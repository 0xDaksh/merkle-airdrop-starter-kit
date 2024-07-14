import Big from "big.js";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { ethers } from "ethers";

const file = Bun.file("./data/values.csv");
const data = (await file.text()).trim();
const seen: Record<string, boolean> = {};
const values: string[][] = [];
let sum = new Big(0);

data.split("\n").map((line, idx) => {
  let [address, amount] = line.split(",");

  if (!ethers.isAddress(address)) {
    if (idx != 0) {
      console.log(
        `Ignoring line ${idx + 1}, can't find an address in "${address}"`
      );
    }
    return;
  }

  address = ethers.getAddress(address);

  if (seen[address]) {
    console.info(
      `Address ${address} is repeated multiple times. Please verify in case this is not intended!`
    );
  }

  seen[address] = true;
  values.push([address, amount]);
  sum = sum.plus(Big(amount));
});

const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
console.log("Total amount:", sum.toString());
console.log("Merkle Root:", tree.root);
Bun.write("export/tree.json", JSON.stringify(tree.dump(), null, 2));
Bun.write("export/root.txt", tree.root);
