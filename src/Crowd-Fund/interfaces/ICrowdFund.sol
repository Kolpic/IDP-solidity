// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ICrowdFund {
    /**
     * EVENTS *********
     */
    event CampaignLaunched(uint256 indexed id, address indexed creator, uint256 goal, uint32 startAt, uint32 endAt);
    event CampaignCanceled(uint256 indexed id);
    event Pledged(address indexed pledger, uint256 indexed id, uint256 amount);
    event Unpledged(uint256 indexed id, address indexed pledger, uint256 amount);
    event Claimed(uint256 indexed id, address indexed claimer, uint256 amount);
    event Refunded(uint256 indexed id, address indexed refundee, uint256 amount);

    /**
     * ERRORS *********
     */
    error StartAtIsInThePast();
    error EndAtIsLessThanStartAt();
    error EndAtIsGreaterThanMaxDuration();
    error CampaignNotCreator();
    error CampaignNotStarted();
    error CampaignAlreadyEnded();
    error CampaignPledgedAmountIsLessThanGoal();
    error CampaignAlreadyClaimed();
    error CampaignNotEnded();

    /**
     * FUNCTIONS *********
     */
    function launch(uint256 _goal, uint32 _startAt, uint32 _endAt) external;
    function cancel(uint256 _id_) external;
    function pledge(uint256 _id, uint256 _amount) external;
    function unpledge(uint256 _id, uint256 _amount) external;
    function claim(uint256 _id) external;
    function refund(uint256 _id) external;
}
