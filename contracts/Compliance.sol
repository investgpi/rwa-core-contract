// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IIdentityRegistry {
    function isVerified(address user) external view returns (bool);
    function getJurisdiction(address user) external view returns (uint256);
    function getRole(address user) external view returns (bytes32);
}

/**
 * 可配置的合规模块（演示：司法辖区白名单 + 美国锁定期 + 角色要求）
 * 你可以在此扩展：金额上限、黑名单、每日限额、地理组合规则、Reg S/Reg D 分层等。
 */
contract Compliance {
    address public admin;
    IIdentityRegistry public identity;

    // 简化示例：白名单司法辖区
    mapping(uint256 => bool) public allowedJurisdictions;

    // 简化示例：美国(840)投资人需要锁定期才能转让（地址 -> 锁定期截止）
    mapping(address => uint256) public usLockupUntil;

    // 某些接收方需要特定角色，例如 "PROFESSIONAL"（欧盟 MiFID）
    mapping(address => bytes32) public requiredRoleForRecipient; // recipient -> role

    event JurisdictionAllowed(uint256 code, bool allowed);
    event USLockupSet(address indexed user, uint256 until);
    event RequiredRoleSet(address indexed recipient, bytes32 role);
    event AdminChanged(address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Compliance: not admin");
        _;
    }

    constructor(address _admin, address _identity) {
        admin = _admin;
        identity = IIdentityRegistry(_identity);
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
        emit AdminChanged(_admin);
    }

    function allowJurisdiction(uint256 code, bool allowed) external onlyAdmin {
        allowedJurisdictions[code] = allowed;
        emit JurisdictionAllowed(code, allowed);
    }

    function setUSLockup(address user, uint256 until) external onlyAdmin {
        usLockupUntil[user] = until;
        emit USLockupSet(user, until);
    }

    function setRequiredRoleForRecipient(address recipient, bytes32 role) external onlyAdmin {
        requiredRoleForRecipient[recipient] = role;
        emit RequiredRoleSet(recipient, role);
    }

    /**
     * 核心校验：从 from 向 to 转 amount 是否合规
     */
    function canTransfer(address from, address to, uint256 /*amount*/) external view returns (bool, string memory) {
        // 基础：双方必须经过验证且在有效期内
        if (!identity.isVerified(from)) return (false, "KYC: sender not verified/expired");
        if (!identity.isVerified(to))   return (false, "KYC: recipient not verified/expired");

        // 司法辖区白名单
        uint256 jFrom = identity.getJurisdiction(from);
        uint256 jTo   = identity.getJurisdiction(to);
        if (!allowedJurisdictions[jFrom] || !allowedJurisdictions[jTo]) {
            return (false, "JURISDICTION: not allowed");
        }

        // 美国(840)投资人的锁定期（如 Reg D 12 个月）
        if (jFrom == 840 && block.timestamp < usLockupUntil[from]) {
            return (false, "LOCKUP: US sender in lockup");
        }

        // 接收方角色要求（如 MiFID 专业投资者）
        bytes32 req = requiredRoleForRecipient[to];
        if (req != bytes32(0)) {
            if (identity.getRole(to) != req) {
                return (false, "ROLE: recipient role not satisfied");
            }
        }

        return (true, "");
    }
}
