// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICrowdFund} from "./interfaces/ICrowdFund.sol";
import {DataTypes} from "./libs/DataTypes.sol";

contract CrowdFund is ICrowdFund {
    /**
     * STATE VARIABLES *********
     */
    address public immutable TOKEN;
    uint256 public immutable MAX_DURATION;

    uint256 public count;
    mapping(uint256 => DataTypes.Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public pledgedAmount;

    /**
     * CONSTRUCTOR *********
     */
    constructor(address _token, uint256 _maxDuration) {
        TOKEN = _token;
        MAX_DURATION = _maxDuration;
    }

    /**
     * FUNCTIONS *********
     */
    function launch(uint256 _goal, uint32 _startAt, uint32 _endAt) external override {
        if (_startAt < block.timestamp) {
            revert StartAtIsInThePast();
        }
        if (_endAt <= _startAt) {
            revert EndAtIsLessThanStartAt();
        }
        if (_endAt > _startAt + MAX_DURATION) {
            revert EndAtIsGreaterThanMaxDuration();
        }

        count += 1;
        campaigns[count] = DataTypes.Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit CampaignLaunched(count, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint256 _id) external override {
        DataTypes.Campaign memory campaign = campaigns[_id];
        if (msg.sender != campaign.creator) {
            revert CampaignNotCreator();
        }
        if (campaign.startAt > block.timestamp) {
            revert CampaignNotStarted();
        }

        delete campaigns[_id];
        emit CampaignCanceled(_id);
    }

    function pledge(uint256 _id, uint256 _amount) external override {
        DataTypes.Campaign storage campaign = campaigns[_id];

        if (campaign.startAt > block.timestamp) {
            revert CampaignNotStarted();
        }
        if (campaign.endAt < block.timestamp) {
            revert CampaignAlreadyEnded();
        }

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        SafeERC20.safeTransferFrom(IERC20(TOKEN), msg.sender, address(this), _amount);

        emit Pledged(msg.sender, _id, _amount);
    }

    function unpledge(uint256 _id, uint256 _amount) external override {
        DataTypes.Campaign storage campaign = campaigns[_id];

        if (campaign.endAt < block.timestamp) {
            revert CampaignAlreadyEnded();
        }

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        SafeERC20.safeTransferFrom(IERC20(TOKEN), address(this), msg.sender, _amount);

        emit Unpledged(_id, msg.sender, _amount);
    }

    function claim(uint256 _id) external override {
        DataTypes.Campaign storage campaign = campaigns[_id];

        if (msg.sender != campaign.creator) {
            revert CampaignNotCreator();
        }
        if (block.timestamp < campaign.endAt) {
            revert CampaignNotEnded();
        }
        if (campaign.pledged < campaign.goal) {
            revert CampaignPledgedAmountIsLessThanGoal();
        }
        if (campaign.claimed) {
            revert CampaignAlreadyClaimed();
        }

        campaign.claimed = true;
        SafeERC20.safeTransfer(IERC20(TOKEN), msg.sender, campaign.pledged);

        emit Claimed(_id, msg.sender, campaign.pledged);
    }

    function refund(uint256 _id) external override {
        DataTypes.Campaign storage campaign = campaigns[_id];

        if (block.timestamp < campaign.endAt) {
            revert CampaignNotEnded();
        }
        if (campaign.pledged >= campaign.goal) {
            revert CampaignPledgedAmountIsLessThanGoal();
        }

        uint256 balance = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        SafeERC20.safeTransfer(IERC20(TOKEN), msg.sender, balance);

        emit Refunded(_id, msg.sender, balance);
    }
}
