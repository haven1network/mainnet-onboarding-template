// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract FixedFeeOracle is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 private _val;

    constructor(address association_, uint256 val_) {
        _grantRole(DEFAULT_ADMIN_ROLE, association_);
        _grantRole(OPERATOR_ROLE, association_);
        _val = val_;
    }

    function refreshOracle() external pure returns (bool) {
        return true;
    }

    function updateVal(uint256 v) external onlyRole(OPERATOR_ROLE) {
        _val = v;
    }

    function consult() external view returns (uint256) {
        return _val;
    }
}
