const hre = require("hardhat");

// 用真实部署地址替换
const IR_ADDR = "0x621E427e081Bf8F366e70213C9082b1817357e7f";   // IdentityRegistry
const COMP_ADDR = "0xD881F04F0E0ff688AaAfc7b9e279D9d3ab886aB3"; // Compliance
const ST_ADDR = "0xf9BD8824bce013f29A340bc44f000Eb37DA7a5E3";   // SecurityToken

// 示例地址（发给同事/投资者的测试钱包）
const INVESTOR_US = "0xf4a2d5e1a29A32F6336803B52fa349cED34dAD27";   // 美国投资人
const INVESTOR_EU = "0x9c28162EB3D7ff34aC3EAca9F98CBd12d9F3CfE6";   // 欧盟投资人

async function main() {
  const [admin] = await hre.ethers.getSigners();

  const ir = await hre.ethers.getContractAt("IdentityRegistry", IR_ADDR);
  const comp = await hre.ethers.getContractAt("Compliance", COMP_ADDR);
  const st = await hre.ethers.getContractAt("SecurityToken", ST_ADDR);

  const now = Math.floor(Date.now() / 1000);
  const oneYear = 365 * 24 * 60 * 60;

  // 1) 注册身份
  // 美国投资人：isVerified=true, jurisdiction=840, role="ACCREDITED", 有效期1年
  await (await ir.setIdentity(INVESTOR_US, true, 840, hre.ethers.encodeBytes32String("ACCREDITED"), now + oneYear)).wait();

  // 欧盟投资人：isVerified=true, jurisdiction=276, role="PROFESSIONAL"
  await (await ir.setIdentity(INVESTOR_EU, true, 276, hre.ethers.encodeBytes32String("PROFESSIONAL"), now + oneYear)).wait();

  // 2) 针对“美国投资人”设置锁定期（比如Reg D 12个月）
  await (await comp.setUSLockup(INVESTOR_US, now + oneYear)).wait();

  // 可选：要求某接收方必须具备“PROFESSIONAL”角色
  // await (await comp.setRequiredRoleForRecipient(INVESTOR_EU, hre.ethers.encodeBytes32String("PROFESSIONAL"))).wait();

  // 3) 铸币给美国投资人
  await (await st.mint(INVESTOR_US, hre.ethers.parseUnits("1000", 18))).wait();

  console.log("Setup done.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
