// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


interface IBEP20 {
	function totalSupply() external view returns (uint256);
	
	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);
	
	function allowance(address owner, address spender) external view returns (uint256);
	
	function approve(address spender, uint256 amount) external returns (bool);
	
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	
	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address payable){
		return payable(msg.sender);
	}

	function _msgData() internal view virtual returns (bytes memory){
		this;
		return msg.data;
	}
}

contract Ownable is Context { 
	address private _owner;
	address private _previousOwner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor (){
		_owner = 0xF26Bd6b4cdb1cC7982a655C48F76550038986A52; 
		emit OwnershipTransferred(address(0),_owner); 
	}

	function owner() public view returns (address){
		return _owner;
	}

	modifier onlyOwner(){
		require(_owner == _msgSender(),"Caller is not the owner");  
		_;
	}

	function renounceOwnership() public virtual onlyOwner{
		emit OwnershipTransferred(_owner, address(0));

		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner{
		require(newOwner != address(0),"Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner,newOwner);
		_owner = newOwner;
	}
}

library Address{
	function isContract(address account) internal view returns (bool){

		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		assembly {codehash := extcodehash(account)}
		return(codehash != accountHash && codehash !=0x0);
	}
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");

		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
	}


	function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}


	function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		return _functionCallWithValue(target, data, value, errorMessage);
	}
	function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");

		(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
		if (success) {
				return returndata;
		} else {
			if (returndata.length > 0) {

				assembly {
						let returndata_size := mload(returndata)
						revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
} 

abstract contract ReentrancyGuard{
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor () {
		_status = _NOT_ENTERED;
	}
	modifier nonReentrant() {
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

		_status = _ENTERED;
		_;

	
		_status = _NOT_ENTERED;
	}
}


contract TestCoin is Context, IBEP20, Ownable, ReentrancyGuard {
	using Address for address; 

	string constant private _symbol = "TC";
	string constant private _name = "TestCoin";
	uint8 constant private _decimals = 9;

	uint256 constant private _tTotal = 50000000000 * 10**4 * 10**9; // 500T total supply

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;


	mapping(address => bool) private _isExcludedFromFee;

	uint256 public burnFeePercent  = 0; // 5
	uint256 public prevBurnFee	   = 5;   

	uint256 public liqFeePercent = 0; //5       
	uint256 private prevLiqFee	 = 5;
	

	uint256 private _tLiqTotal;

	uint256 private _tBurnTotal;

	bool inSwapAndLiquify;
	bool public inSwapAndLiquifyEnabled = false;
	uint256 constant maxTokensToLiquify = _tTotal / 1000 * 5;
	uint256 constant TokensToSellForLiq = _tTotal / 1000;

	IPancakeRouter02 public immutable pancakeRouter;
	address public immutable pancakePair;
	event SwapAndLiquify(uint256 tokensSwapped,
		uint256 bnbReceived,
		uint256 tokensIntoLiquidity
	);

	modifier lockTheSwap{
		inSwapAndLiquify = true;
		_;
		inSwapAndLiquify = false;
	}

	constructor() {
    // testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
		IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
		pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
		pancakeRouter = _pancakeRouter;
		
		_balances[msg.sender] = _tTotal;
		emit Transfer(address(0), payable(msg.sender), _tTotal);
	}

	receive() external payable{}

	function getOwner() external view returns (address) {
		return owner();
	}
 
	function decimals() external pure returns (uint8) {
		return _decimals;
	}
 
	function symbol() external pure returns (string memory) {
		return _symbol;
	}
 
	function name() external pure returns (string memory) {
		return _name;
	}
	
	function totalSupply() public pure override returns (uint256) {
		return _tTotal;
	}

	function balanceOf(address account) public view override returns (uint256) {
		return _balances[account];
	}
 
	
	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return _allowances[owner][spender];
	}
	
	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		require(amount <= _allowances[sender][_msgSender()], "BEP20: transfer amount exceeds allowance");
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		require(subtractedValue <= _allowances[_msgSender()][spender], "BEP20: decreased allowance below zero");
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
		return true;
	}

	function _transfer(address sender, address recipient, uint256 amount) internal {
		require(sender != address(0), "BEP20: transfer from the zero address");
		require(recipient != address(0), "BEP20: transfer to the zero address");
		
		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");

		uint256 currentContractBalance = balanceOf(address(this));

		if(currentContractBalance >= TokensToSellForLiq && 
			!inSwapAndLiquify && 
			sender != pancakePair && 
			inSwapAndLiquifyEnabled
		){
			if(currentContractBalance >= maxTokensToLiquify){
				currentContractBalance = maxTokensToLiquify;
			} 
			currentContractBalance = TokensToSellForLiq;
			
			swapAndLiquify(currentContractBalance);
		}

		bool takeFee = true;
		if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
			takeFee = false;
		}

		uint256 burnAmount = 0; 
		uint256 liqAmount = 0;  

		if(takeFee) {
			burnAmount = amount * burnFeePercent/100;
			liqAmount = amount * liqFeePercent/100;
		}

		_balances[sender] = senderBalance - amount;
		_balances[recipient] += amount - burnAmount - liqAmount;

		if(burnAmount != 0) {
			_balances[0x000000000000000000000000000000000000dEaD] += burnAmount;
			_tBurnTotal += burnAmount;
			emit Transfer(sender, 0x000000000000000000000000000000000000dEaD, burnAmount);
		}

		if(liqAmount != 0) {
			_balances[address(this)] += liqAmount;
			_tLiqTotal += liqAmount;
			emit Transfer(sender, address(this), liqAmount);
		}
		
		emit Transfer(sender, recipient, amount);
	}
	
	function isExcludedFromFees(address account) public virtual returns (bool) {
		return _isExcludedFromFee[account];
	}

	function totalLiquidityTokens() external view returns(uint256){
		return _tLiqTotal;
	}

	function totalBurn() external view returns (uint256){
		return _tBurnTotal;
	}

	function _approve(address owner, address spender, uint256 amount) internal {
		require(owner != address(0), "BEP20: approve from the zero address");
		require(spender != address(0), "BEP20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function stopFees() external onlyOwner() {
		if(burnFeePercent == 0 && liqFeePercent == 0) return;
		
		prevBurnFee = burnFeePercent;
		burnFeePercent = 0;

		prevLiqFee = liqFeePercent;
		liqFeePercent = 0;
	}

	function restoreFees() public onlyOwner(){
		if(burnFeePercent > 0 && liqFeePercent > 0) return;
		burnFeePercent = prevBurnFee;
		liqFeePercent = prevLiqFee;
	}

	function InitializeTokenomics() external onlyOwner() {
		restoreFees();
		inSwapAndLiquifyEnabled = true;
	}

	function setSwapAndLiquify(bool enabled) external onlyOwner() {
		inSwapAndLiquifyEnabled = enabled;
	}

	function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
		uint256 half = contractTokenBalance / 2;
		uint256 otherHalf = contractTokenBalance - half;
		uint256 initialBalance = address(this).balance;

		swapTokensForBNB(half);
		uint256 newBalance = address(this).balance - (initialBalance); 

		addLiquidity(otherHalf, newBalance);
		emit SwapAndLiquify(half,newBalance,otherHalf);
	}

	function swapTokensForBNB(uint256 tokenAmount) private{
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = pancakeRouter.WETH();
		_approve(address(this), address(pancakeRouter), tokenAmount);

		pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, 
			path,
			address(this),
			block.timestamp
		);
	}

	function addLiquidity(uint256 tokenAmount,uint256 bnbAmount) private{
		_approve(address(this), address(pancakeRouter), tokenAmount);

		pancakeRouter.addLiquidityETH{value:bnbAmount}(
			address(this),
			tokenAmount,
			0,
			0,
			owner(),
			block.timestamp
		);
	}
}

interface IPancakeFactory{
		event PairCreated(address indexed token0, address indexed token1, address pair, uint);

		function feeTo() external view returns (address);
		function feeToSetter() external view returns (address);

		function getPair(address tokenA, address tokenB) external view returns (address pair);
		function allPairs(uint) external view returns (address pair);
		function allPairsLength() external view returns (uint);

		function createPair(address tokenA, address tokenB) external returns (address pair);

		function setFeeTo(address) external;
		function setFeeToSetter(address) external;
}


interface IPancakePair{
		event Approval(address indexed owner, address indexed spender, uint value);
		event Transfer(address indexed from, address indexed to, uint value);

		function name() external pure returns (string memory);
		function symbol() external pure returns (string memory);
		function decimals() external pure returns (uint8);
		function totalSupply() external view returns (uint);
		function balanceOf(address owner) external view returns (uint);
		function allowance(address owner, address spender) external view returns (uint);

		function approve(address spender, uint value) external returns (bool);
		function transfer(address to, uint value) external returns (bool);
		function transferFrom(address from, address to, uint value) external returns (bool);

		function DOMAIN_SEPARATOR() external view returns (bytes32);
		function PERMIT_TYPEHASH() external pure returns (bytes32);
		function nonces(address owner) external view returns (uint);

		function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

		event Mint(address indexed sender, uint amount0, uint amount1);
		event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
		event Swap(
				address indexed sender,
				uint amount0In,
				uint amount1In,
				uint amount0Out,
				uint amount1Out,
				address indexed to
		);
		event Sync(uint112 reserve0, uint112 reserve1);

		function MINIMUM_LIQUIDITY() external pure returns (uint);
		function factory() external view returns (address);
		function token0() external view returns (address);
		function token1() external view returns (address);
		function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
		function price0CumulativeLast() external view returns (uint);
		function price1CumulativeLast() external view returns (uint);
		function kLast() external view returns (uint);

		function mint(address to) external returns (uint liquidity);
		function burn(address to) external returns (uint amount0, uint amount1);
		function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
		function skim(address to) external;
		function sync() external;

		function initialize(address, address) external;

}

interface IPancakeRouter01 {
		function factory() external pure returns (address);
		function WETH() external pure returns (address);

		function addLiquidity(
				address tokenA,
				address tokenB,
				uint amountADesired,
				uint amountBDesired,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline
		) external returns (uint amountA, uint amountB, uint liquidity);
		function addLiquidityETH(
				address token,
				uint amountTokenDesired,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline
		) external payable returns (uint amountToken, uint amountETH, uint liquidity);
		function removeLiquidity(
				address tokenA,
				address tokenB,
				uint liquidity,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline
		) external returns (uint amountA, uint amountB);
		function removeLiquidityETH(
				address token,
				uint liquidity,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline
		) external returns (uint amountToken, uint amountETH);
		function removeLiquidityWithPermit(
				address tokenA,
				address tokenB,
				uint liquidity,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline,
				bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountA, uint amountB);
		function removeLiquidityETHWithPermit(
				address token,
				uint liquidity,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline,
				bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountToken, uint amountETH);
		function swapExactTokensForTokens(
				uint amountIn,
				uint amountOutMin,
				address[] calldata path,
				address to,
				uint deadline
		) external returns (uint[] memory amounts);
		function swapTokensForExactTokens(
				uint amountOut,
				uint amountInMax,
				address[] calldata path,
				address to,
				uint deadline
		) external returns (uint[] memory amounts);
		function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
		external
		payable
		returns (uint[] memory amounts);
		function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
		external
		returns (uint[] memory amounts);
		function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
		external
		returns (uint[] memory amounts);
		function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
		external
		payable
		returns (uint[] memory amounts);

		function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
		function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
		function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
		function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
		function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {  
		function removeLiquidityETHSupportingFeeOnTransferTokens(
				address token,
				uint liquidity,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline
		) external returns (uint amountETH);
		function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
				address token,
				uint liquidity,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline,
				bool approveMax, uint8 v, bytes32 r, bytes32 s
		) external returns (uint amountETH);

		function swapExactTokensForTokensSupportingFeeOnTransferTokens(
				uint amountIn,
				uint amountOutMin,
				address[] calldata path,
				address to,
				uint deadline
		) external;
		function swapExactETHForTokensSupportingFeeOnTransferTokens(
				uint amountOutMin,
				address[] calldata path,
				address to,
				uint deadline
		) external payable;
		function swapExactTokensForETHSupportingFeeOnTransferTokens(
				uint amountIn,
				uint amountOutMin,
				address[] calldata path,
				address to,
				uint deadline
		) external;
}