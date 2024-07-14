import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

const treeData = await Bun.file("./export/tree.json").json();

const tree = StandardMerkleTree.load(treeData);

for (const [i, v] of tree.entries()) {
  if (v[0] === "0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5") {
    // (3)
    const proof = tree.getProof(i);
    console.log("Value:", v);
    console.log("Proof:", proof);
  }
}
