// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.5;

// import "../Equb.sol";

// contract FundTransfer {
//     mapping(address => uint256) public equbBalances;
//     mapping(address => address) public externalStartupWallets;

//     function contributeToEqub(address equb, uint256 amount) public {
//         equbBalances[equb] += amount;
//     }

//     function transferFunds(address equb, uint256 amount) public {
//         require(
//             equbBalances[equb] >= amount,
//             "Insufficient funds in equb balance"
//         );

//         address payable externalStartupWallet = address(
//             externalStartupWallets[equb]
//         );
//         externalStartupWallet.transfer(amount);

//         equbBalances[equb] -= amount;
//     }

//     function addStartupWallet(
//         address equb,
//         address externalStartupWallet
//     ) public {
//         externalStartupWallets[equb] = externalStartupWallet;
//     }
// }
