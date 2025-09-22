// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * 轻量身份注册表：
 * - isVerified: 是否通过KYC/AML
 * - jurisdiction: 司法辖区（自定义编码，如 840=USA, 724=ESP, 156=CHN 等）
 * - role: 角色，如 "ACCREDITED", "PROFESSIONAL" 等（bytes32存储）
 * - validUntil: 资格有效期时间戳
 */
contract IdentityRegistry {
    struct Identity {
        bool isVerified;
        uint256 jurisdiction;
        bytes32 role;
        uint64 validUntil;
    }

    address public admin;
    mapping(address => Identity) private identities;

    event IdentityUpdated(address indexed user, bool isVerified, uint256 jurisdiction, bytes32 role, uint64 validUntil);

    modifier onlyAdmin() {
        require(msg.sender == admin, "IR: not admin");
        _;
    }

    constructor(address _admin) {
        admin = _admin;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    function setIdentity(
        address user,
        bool isVerified,
        uint256 jurisdiction,
        bytes32 role,
        uint64 validUntil
    ) external onlyAdmin {
        identities[user] = Identity(isVerified, jurisdiction, role, validUntil);
        emit IdentityUpdated(user, isVerified, jurisdiction, role, validUntil);
    }

    function getIdentity(address user) external view returns (Identity memory) {
        return identities[user];
    }

    function isVerified(address user) external view returns (bool) {
        Identity memory id = identities[user];
        return id.isVerified && block.timestamp <= id.validUntil;
    }

    function getJurisdiction(address user) external view returns (uint256) {
        return identities[user].jurisdiction;
    }

    function getRole(address user) external view returns (bytes32) {
        return identities[user].role;
    }
}
