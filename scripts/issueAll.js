// scripts/issueAll.js
const hre = require("hardhat");

async function main() {
  const {
    TOKEN_ADDRESS,      // 已部署的 SecurityToken 合约地址
    ADMIN_ADDRESS,      // 接收全部代币的管理员地址
    TOTAL_SUPPLY,       // 需要发行的总代币数量（不含小数位）
    DECIMALS = "18",    // 代币小数位（默认18）
  } = process.env;

  if (!TOKEN_ADDRESS || !ADMIN_ADDRESS || !TOTAL_SUPPLY) {
    throw new Error("请在 .env 中设置 TOKEN_ADDRESS, ADMIN_ADDRESS, TOTAL_SUPPLY, (可选)DECIMALS");
  }

  const [signer] = await hre.ethers.getSigners();
  console.log("Issuer (tx signer):", signer.address);

  const token = await hre.ethers.getContractAt("SecurityToken", TOKEN_ADDRESS);

  // 1) 检查调用者是否具备 TRANSFER_AGENT_ROLE
  const TA_ROLE = await token.TRANSFER_AGENT_ROLE();
  const hasRole = await token.hasRole(TA_ROLE, signer.address);
  if (!hasRole) {
    throw new Error("当前签名地址没有 TRANSFER_AGENT_ROLE，无法发行。请先授予角色。");
  }

  // 2) 确认是否已发行过
  const currentSupply = await token.totalSupply();
  if (currentSupply > 0n) {
    console.log(`已存在供给: ${currentSupply.toString()}，为避免重复发行，脚本终止。`);
    return;
  }

  // 3) 计算发行量（带小数位）
  const amount = hre.ethers.parseUnits(TOTAL_SUPPLY, Number(DECIMALS));
  console.log(`准备发行 ${TOTAL_SUPPLY} (10^${DECIMALS}) 到 ${ADMIN_ADDRESS}`);

  // 4) 执行 mint 到管理员地址
  const tx = await token.mint(ADMIN_ADDRESS, amount);
  console.log("mint tx:", tx.hash);
  const receipt = await tx.wait();
  console.log("✅ 发行完成，区块:", receipt.blockNumber);

  // 5) 打印结果
  const newSupply = await token.totalSupply();
  const adminBal = await token.balanceOf(ADMIN_ADDRESS);
  console.log("totalSupply:", newSupply.toString());
  console.log("admin balance:", adminBal.toString());
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
