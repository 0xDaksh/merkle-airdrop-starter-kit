// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Airdrop is Initializable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    event Claimed(address indexed user, bytes32 leaf, uint256 amount);

    error InvalidTokenAddress();
    error InvalidTimestamps();
    error InvalidFunder();
    error ClaimNotActive();
    error UserNotAllowed();
    error AlreadyClaimed();
    error InvalidProof();

    IERC20 public token;
    address public funder;
    bytes32 public merkleRoot;
    uint256 public start;
    uint256 public end;

    mapping(bytes32 => bool) public leafClaimed;
    mapping(address => bool) public notAllowed;

    constructor() {
        _disableInitializers();
    }

    function initialize(address owner_, address token_, address funder_, bytes32 root_, uint256 start_, uint256 end_)
        external
        initializer
    {
        if (token_ == address(0)) revert InvalidTokenAddress();

        __Ownable_init(owner_);
        __Pausable_init();

        token = IERC20(token_);
        funder = funder_;
        merkleRoot = root_;
        start = start_;
        end = end_;
    }

    function updateRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function updateFunder(address funder_) external onlyOwner {
        if (funder_ == address(0)) revert InvalidFunder();

        funder = funder_;
    }

    function updateTimestamps(uint256 start_, uint256 end_) external onlyOwner {
        if (block.timestamp > start || start_ >= end_) revert InvalidTimestamps();

        start = start_;
        end = end_;
    }

    function disallowUsers(address[] calldata users_, bool status_) external onlyOwner {
        for (uint256 i; i < users_.length;) {
            notAllowed[users_[i]] = status_;
            unchecked {
                ++i;
            }
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function claim(uint256 amt, bytes32[] calldata merkleProof) external whenNotPaused {
        /// if current timestamp is before starting timestamp
        /// or current timestamp is after ending timestamp
        if (block.timestamp < start || block.timestamp >= end) revert ClaimNotActive();

        if (notAllowed[msg.sender]) revert UserNotAllowed();

        bytes32 leaf = getLeaf(msg.sender, amt);

        if (leafClaimed[leaf]) revert AlreadyClaimed();

        if (!MerkleProof.verifyCalldata(merkleProof, merkleRoot, leaf)) revert InvalidProof();

        leafClaimed[leaf] = true;
        token.safeTransferFrom(funder, msg.sender, amt);

        emit Claimed(msg.sender, leaf, amt);
    }

    function verifyProof(address user, uint256 amt, bytes32[] calldata merkleProof) external view returns (bool) {
        bytes32 leaf = getLeaf(user, amt);
        return MerkleProof.verifyCalldata(merkleProof, merkleRoot, leaf);
    }

    function getLeaf(address user, uint256 amt) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(user, amt))));
    }
}
