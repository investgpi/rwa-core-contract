const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // 1) 部署 IdentityRegistry
  const IR = await hre.ethers.getContractFactory("IdentityRegistry");
  const ir = await IR.deploy(deployer.address);
  await ir.waitForDeployment();
  console.log("IdentityRegistry:", await ir.getAddress());

  // 2) 部署 Compliance
  const Compliance = await hre.ethers.getContractFactory("Compliance");
  const comp = await Compliance.deploy(deployer.address, await ir.getAddress());
  await comp.waitForDeployment();
  console.log("Compliance:", await comp.getAddress());

  // 3) 部署 SecurityToken
  const ST = await hre.ethers.getContractFactory("SecurityToken");
  const st = await ST.deploy("Acme RWA Fund", "ARF", deployer.address, await comp.getAddress());
  await st.waitForDeployment();
  console.log("SecurityToken:", await st.getAddress());

  // 4) 基础规则演示（可选）
  // 允许美国840、欧盟某国等司法辖区
  await (await comp.allowJurisdiction(840, true)).wait(); // USA
  await (await comp.allowJurisdiction(276, true)).wait(); // Germany
  await (await comp.allowJurisdiction(250, true)).wait(); // France
  await (await comp.allowJurisdiction(156, true)).wait(); // China (示例)
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
