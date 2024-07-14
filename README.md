# Merkle Airdrop Starter Kit

The simplest no bs way to create a merkle-tree based airdrop. This starter kit comes up with the following:

- Latest libs: Foundry, Solidity & OZ 5.0 support
- Upgradability
- Separation of Airdrop contract and Funds
- Not allowed users list
- Pausability
- Timestamp constrained claims
- CSV2Tree Generator and an example proof getter

## How to get started?

### Generate a Merkle Tree

Save your airdrop data in `generator/data/values.csv`, the format can be found in `generator/data/example.csv`.

Run the following command to generate the merkle tree:

```bash
cd generator
bun csv2tree.ts
```

This will export a merkle tree (`export/tree.json`) and it's root (`export/root.txt`) in the `export/` folder

### Deploy the Airdrop contract

Update the values of the following in the [DeployAirdrop.s.sol](./script/DeployAirdrop.s.sol) script:

- Token
- Owner
- Funder
- MerkleRoot (can be found in `generator/export/root.txt`)
- Start Time
- End Time

Once you have changed the placeholders, run the following command:

```bash
forge script script/DeployAirdrop.s.sol --broadcast --rpc-url $RPC_URL --private-key $PK --optimizer-runs 999
```

You should pass the RPC URL of the chain you want to deploy to and your private key as environment variables.
**Note:** For production deployments ideally use a keystore instead of passing the private key directly.

### How to get the merkle proof for a given address

You can use the `getProof.ts` script in the `generator` folder to get the merkle proof for a given address.

```bash
cd generator
bun getProof.ts # feel free to edit the file and change the address
```

### Run Tests

```bash
forge test
```
