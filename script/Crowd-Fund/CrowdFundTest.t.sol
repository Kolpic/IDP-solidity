// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../src/Crowd-Fund/CrowdFund.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 1. MOCK TOKEN FOR TESTING
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock", "MCK") {}
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract CrowdFundTest is Test {
    CrowdFund public crowdFund;
    MockERC20 public token;

    address public creator = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    uint256 public constant MAX_DURATION = 30 days;

    function setUp() public {
        token = new MockERC20();
        crowdFund = new CrowdFund(address(token), MAX_DURATION);

        // Fund users
        token.mint(user1, 1000 ether);
        token.mint(user2, 1000 ether);

        // Approve CrowdFund to spend users' tokens
        vm.prank(user1);
        token.approve(address(crowdFund), type(uint256).max);
        vm.prank(user2);
        token.approve(address(crowdFund), type(uint256).max);
    }

    /* ==========================================================================
       UNIT TESTS (Testing specific functionality)
       ========================================================================== */

    function testLaunchCampaign() public {
        vm.prank(creator);
        // Start now, end in 1 day
        crowdFund.launch(100 ether, uint32(block.timestamp), uint32(block.timestamp + 1 days));
        
        (address _creator, uint _goal, uint _pledged,,,) = crowdFund.campaigns(1);
        assertEq(_creator, creator);
        assertEq(_goal, 100 ether);
        assertEq(_pledged, 0);
    }

    function testPledge() public {
        // 1. Launch
        vm.prank(creator);
        crowdFund.launch(100 ether, uint32(block.timestamp), uint32(block.timestamp + 1 days));

        // 2. Pledge
        vm.prank(user1);
        crowdFund.pledge(1, 50 ether);

        // 3. Check State
        (,, uint pledged,,,) = crowdFund.campaigns(1);
        assertEq(pledged, 50 ether);
        assertEq(token.balanceOf(address(crowdFund)), 50 ether);
    }

    function testClaimSuccess() public {
        // 1. Launch
        vm.prank(creator);
        crowdFund.launch(100 ether, uint32(block.timestamp), uint32(block.timestamp + 1 days));

        // 2. Pledge Goal Amount
        vm.prank(user1);
        crowdFund.pledge(1, 100 ether);

        // 3. Warp time to after end
        vm.warp(vm.getBlockTimestamp() + 2 days);

        // 4. Claim
        vm.prank(creator);
        crowdFund.claim(1);

        // 5. Verify tokens moved to creator
        assertEq(token.balanceOf(creator), 100 ether);
    }

    function testRefundSuccess() public {
        // 1. Launch
        vm.prank(creator);
        crowdFund.launch(100 ether, uint32(block.timestamp), uint32(block.timestamp + 1 days));

        // 2. Pledge LESS than goal
        vm.prank(user1);
        crowdFund.pledge(1, 50 ether);

        // 3. Warp time to after end
        vm.warp(block.timestamp + 2 days);

        // 4. Refund
        uint256 balanceBefore = token.balanceOf(user1);
        vm.prank(user1);
        crowdFund.refund(1);

        // 5. Verify tokens returned
        assertEq(token.balanceOf(user1), balanceBefore + 50 ether);
    }

    /* ==========================================================================
       FUZZ TESTS (Testing random inputs)
       ========================================================================== */
    
    // Foundry will run this function hundreds of times with random numbers for `amount`
    function testFuzz_Pledge(uint96 amount) public {
        // Constraint: Don't pledge 0, don't pledge more than user has
        vm.assume(amount > 0); 
        vm.assume(amount <= 1000 ether);

        vm.prank(creator);
        crowdFund.launch(2000 ether, uint32(block.timestamp), uint32(block.timestamp + 1 days));

        vm.prank(user1);
        crowdFund.pledge(1, amount);

        (,, uint pledged,,,) = crowdFund.campaigns(1);
        assertEq(pledged, amount);
    }

    // Test Launch with random timestamps
    function testFuzz_LaunchDates(uint32 startAt, uint32 endAt) public {
        // Constraints to ensure valid inputs
        vm.assume(startAt >= block.timestamp);
        vm.assume(endAt > startAt);
        vm.assume(endAt <= startAt + MAX_DURATION);

        vm.prank(creator);
        crowdFund.launch(100 ether, startAt, endAt);
        
        (,,, uint32 s, uint32 e,) = crowdFund.campaigns(1);
        assertEq(s, startAt);
        assertEq(e, endAt);
    }

    /* ==========================================================================
       INVARIANT TESTS (Properties that must ALWAYS be true)
       ========================================================================== */
    
    function testInvariant_ContractBalanceMatchesPledges() public {
        // 1. Setup a scenario with multiple pledges
        vm.prank(creator);
        crowdFund.launch(1000 ether, uint32(block.timestamp), uint32(block.timestamp + 1 days));

        vm.prank(user1);
        crowdFund.pledge(1, 100 ether);
        vm.prank(user2);
        crowdFund.pledge(1, 200 ether);

        // INVARIANT: The contract's token balance must equal the sum of pledges
        // no claims have happened yet)
        assertEq(token.balanceOf(address(crowdFund)), 300 ether);
    }
}