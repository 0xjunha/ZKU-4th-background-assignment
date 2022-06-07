pragma solidity ^0.8.4;
import "hardhat/console.sol";


contract Purchase {


  uint public value;
  address payable public seller;
  address payable public buyer;
  uint public purchaseConfirmedTimestamp;  // NEW

  enum State { Created, Locked, Release, Inactive }

  State public state;  // default = `State.Created`

  modifier condition(bool condition_) {
    require(condition_);
    _;
  }


  error OnlyBuyer();
  error OnlySeller();
  error InvalidState();
  error ValueNotEven();
  error InvalidTimestamp();  // NEW


  // NEW
  modifier completePurchasePermission() {
    // Block's timestamp can be assumed as representative of real time.
    uint currentTimestamp = block.timestamp;

    if (msg.sender != buyer && currentTimestamp < purchaseConfirmedTimestamp + 5 * 60)
      revert InvalidTimestamp();
    _;
  }

  modifier onlyBuyer() {
    if (msg.sender != buyer)
      revert OnlyBuyer();
    _;
  }

  modifier onlySeller() {
    if (msg.sender != seller)
      revert OnlySeller();
    _;
  }

  modifier inState(State state_) {
    if (state != state_)
      revert InvalidState();
    _;
  }

  event Aborted();
  event PurchaseConfirmed();
  event ItemReceived();
  event SellerRefunded();
  event PurchaseCompleted();  // NEW

  // Constructor with a `payable` modifier.
  constructor() payable {
    seller = payable(msg.sender);  // Seller deploys the contract.
    value = msg.value / 2;
    if ((2 * value) != msg.value)
      revert ValueNotEven();
    console.log('Deployment Timestamp: ', block.timestamp);  // Logging on console to record deployment timestamp.
  }

  function abort()
    external
    onlySeller
    inState(State.Created)
  {
    emit Aborted();
    state = State.Inactive;
    seller.transfer(address(this).balance);  // Transfer balance of the contract to the seller.
  }

  function confirmPurchase()
    external
    inState(State.Created)
    condition(msg.value == (2 * value))
    payable
  {
    emit PurchaseConfirmed();
    buyer = payable(msg.sender);  // Set the buyer.
    state = State.Locked;

    // Record timestamp of current block when this function is called.
    purchaseConfirmedTimestamp = block.timestamp;
  }

  function confirmReceived()
    external
    onlyBuyer
    inState(State.Locked)
  {
    emit ItemReceived();
    state = State.Release;

    buyer.transfer(value);
  }

  function refundSeller()
    external
    onlySeller
    inState(State.Release)
  {
    emit SellerRefunded();
    state = State.Inactive;

    seller.transfer(3 * value);
  }

  function completePurchase()
    external
    completePurchasePermission
    inState(State.Locked)
  {
    emit PurchaseCompleted();

    state = State.Inactive;

    buyer.transfer(value);
    seller.transfer(3 * value);
    console.log('completePurchase() call TimeStamp: ', block.timestamp);
  }
}
