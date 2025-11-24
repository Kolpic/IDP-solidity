// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ICrowdFund {
    /********** EVENTS **********/
    event CampaignLaunched(uint indexed id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event CampaignCanceled(uint indexed id);
    event Pledged(address indexed pledger, uint indexed id, uint amount);
    event Unpledged(uint indexed id, address indexed pledger, uint amount);
    event Claimed(uint indexed id, address indexed claimer, uint amount);
    event Refunded(uint indexed id, address indexed refundee, uint amount);

    /********** ERRORS **********/
    error StartAtIsInThePast();
    error EndAtIsLessThanStartAt();
    error EndAtIsGreaterThanMaxDuration();
    error CampaignNotCreator();
    error CampaignNotStarted();
    error CampaignAlreadyEnded();
    error CampaignPledgedAmountIsLessThanGoal();
    error CampaignAlreadyClaimed();
    error CampaignNotEnded();

    /********** FUNCTIONS **********/
    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external;
    function cancel(uint _id_) external;
    function pledge(uint _id, uint _amount) external;
    function unpledge(uint _id, uint _amount) external;
    function claim(uint _id) external;
    function refund(uint _id) external;
}