pragma solidity ^0.4.14;


contract EscrowSale {
	struct OrderDetails{
		address buyer;
		address seller;
		address arbitrator;
		uint amount;
		bool status;
		bool used;
		bool recieved;
	}
	address public creator;
	mapping(bytes32 => OrderDetails)public orderdata;
	mapping(address => bool) public adminlist;

	function EscrowSale() public {
		creator = msg.sender;
	}

	modifier onlyCreator {  // only creator of contract is allowed to add admin
		if (msg.sender == creator)
		_;
	}
	
	event NotifySeller(bytes32 orderid, uint _amount, address _buyer);
	event NotifyConfirmation(bytes32 orderid,address _seller, address _buyer);

	function addMember(address _newadmin) public onlyCreator returns(bool){
		require(!adminlist[_newadmin]);
		adminlist[_newadmin] = true;
		return true;
	}

	function createEscrow(address _buyer,
		address _seller,
		address _arbitrator,
		uint _amount,
		bytes32 orderId) public{
		require(!orderdata[orderId].used);
		require(adminlist[_arbitrator] == true);
		OrderDetails memory sd;
		sd.buyer = _buyer;
		sd.seller = _seller;
		sd.arbitrator = _arbitrator;
		sd.amount = _amount;
		sd.used = true;

		orderdata[orderId] = sd;
	}

	function depositToEscrow(bytes32 _id) public payable {
		require(msg.sender == orderdata[_id].buyer);
		require(msg.value == orderdata[_id].amount);

		orderdata[_id].status = true;
		creator.transfer(msg.value);
		NotifySeller(_id, orderdata[_id].amount, orderdata[_id].buyer);
	}

	function buyerConfirmation(bytes32 _id) public {
		require(msg.sender == orderdata[_id].buyer);

		orderdata[_id].recieved = true;
		NotifyConfirmation(_id,orderdata[_id].seller,orderdata[_id].buyer);
	}

	function finalizeOrder(bytes32 _id) public payable{
		require(msg.sender == orderdata[_id].arbitrator);
		require(orderdata[_id].recieved == true);
		require(orderdata[_id].amount == msg.value);

		orderdata[_id].seller.transfer(orderdata[_id].amount);
	}
}