pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

// 主要作用就是 createPair以及设置 fee的设置者和 fee的多少

contract UniswapV2Factory is IUniswapV2Factory {
    //开发者团队地址，用来切换团队手续费开关，如果不为0则 开发者会收取0.0%的手续费
    address public feeTo;

    //设置可以配置fee的地址
    address public feeToSetter;

    //存储pair的地址  token0 => (token 1 => pair address)
    mapping(address => mapping(address => address)) public getPair;

    //所有的pair
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        //初始化 fee的设置地址
        feeToSetter = _feeToSetter;
    }

    /**
     * 返回所有pair的长度
     */
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    /**
     * 创建交易对
     * @param tokenA  交易对的一个token
     * @param tokenB  交易度的另外一个token
     */
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        // 不可以是两个相同的token

        // require(tokenA != tokenB , "Uniswap: Identical_address");
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');

        // 将tokenA 和 tokenB 按照字面地址进行排序
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

         // token0 不能为 address(0) 为什么不用判断token1?
         // 因为上面已经通过大小进行了排序       
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');

        //去重    
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient

        // 去创建pair 具体是在UniswapV2Pair合约做的
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        // 使用abi.encodePacked编码
        //并且使用keccak256对上面的结果进行hash运算，并得到一个字节数组
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // 初始化交易对
        //pair的创建就是通过UniswapV2Pair+ tokenA+tokenB一起创建的
        IUniswapV2Pair(pair).initialize(token0, token1);

        // 存token0 跟token 1 以及pair数据
        // 存两份，担心因为排序出问题找不到以及存在的交易对
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        //存下当前交易对的pair地址
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * 设置fee接受的地址
     * 要求该方法调用必须是 feeToSetter
     * @param _feeTo  fee接受地址
     */
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    /**
     * 设置feeSetter的方法
     * 要求改方法调用者必须是上一个feeSetter，
     * 第一个feeSetter是初始化的时候传入的
     * @param _feeToSetter 
     */
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
