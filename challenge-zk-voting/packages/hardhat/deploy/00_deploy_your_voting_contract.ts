import { artifacts, deployScript } from "../rocketh/deploy.js";
export default deployScript(async ({ deploy, namedAccounts }) => {
  const { deployer } = namedAccounts;
  const verifier = "0x0b99634f793caf0b26aa2cd035c8fc8263b9921c";
  await deploy("Voting", { account: deployer, artifact: artifacts.Voting, args: [deployer, verifier, "Do we support cross-chain bridge integration?"] }, { libraries: { LeanIMT: verifier } });
}, { tags: ["YourVotingContract"] });
