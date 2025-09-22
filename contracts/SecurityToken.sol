// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface ICompliance {
    function canTransfer(address from, address to, uint256 amount) external view returns (bool, string memory);
}

contract SecurityToken is ERC20, AccessControl {
    bytes32 public constant TRANSFER_AGENT_ROLE = keccak256("TRANSFER_AGENT_ROLE");
    ICompliance public compliance;

    event ComplianceChanged(address indexed newCompliance);

    constructor(
        string memory name_,
        string memory symbol_,
        address admin_,
        address compliance_
    ) ERC20(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TRANSFER_AGENT_ROLE, admin_);
        compliance = ICompliance(compliance_);
    }

    function setCompliance(address newCompliance) external onlyRole(DEFAULT_ADMIN_ROLE) {
        compliance = ICompliance(newCompliance);
        emit ComplianceChanged(newCompliance);
    }

    // 发行/赎回通常由 Transfer Agent 管理
    function mint(address to, uint256 amount) external onlyRole(TRANSFER_AGENT_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(TRANSFER_AGENT_ROLE) {
        _burn(from, amount);
    }

    // OZ v5 的转账钩子用 _update；v4 用 _beforeTokenTransfer
    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && to != address(0)) {
            (bool ok, string memory reason) = compliance.canTransfer(from, to, value);
            require(ok, reason);
        }
        super._update(from, to, value);
    }
}
