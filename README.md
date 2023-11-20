**NFTInternalCollectionRevealer**: NFT collection that reveals metadata to tokens in same collection contract
**NFTExternalCollectionRevealer**: NFT collection that reveals metadata to a different collection contract, using a burn and mint mechanism
**VRFv2Consumer**: implementation of a Chainlink VRF subscriber contract that fetches true random values, for generating NFT metadata reveal indices
**NFTInternalCollectionRevealer_mockedVRF**: TEST USE ONLY -> mock implementation of NFTInternalCollectionRevealer, with all VRF function mocked with static, local values
**NFTExternalCollectionRevealer_mockedVRF**: TEST USE ONLY -> mock implementation of NFTInternalCollectionRevealer, with all VRF function mocked with static, local values

Usage instructions:
**VRFv2Consumer**
Owner role:
- ref: https://docs.chain.link/vrf/v2/subscription/examples/get-a-random-number/#create-and-fund-a-subscription -> follow thoroughly to set up a **VRF subscription**
- deploy an instance of the **VRFv2Consumer** contract
- Go to https://vrf.chain.link and sign in to your wallet on the same chain/net you deployed to consumer contract on
- Add the deployed **VRFv2Consumer** contract address as a Consumer
- Make sure the subscription is funding with LINK (real or test LINK, depending if on mainnet or testnet)
  
**NFTInternalCollectionRevealer**/**NFTExternalCollectionRevealer**
Owner role:
- deploy an instance of either contract, depending upon desired reveal mechanism. one of the constructor args shoukd be the address of the deployed **VRFv2Consumer**
  contract from the previous step
- call **confirm_vrf_intialized** from the same Owner (deploy) wallet once Owner has finished doing basic VRF setup
  (i.e. completed *all* steps above, including adding the deployed **VRFv2Consumer** contract address as a consumer
- call **start_reveal** to kick off reveal! Users are now able to mint and reveal their secret, randomized metadata.
- Owner's remaining role is to monitor launch and pause/unpause if needed via the OZ **Pausable** that is inherited

User role:
- call **initiate_reveal_request** -> this fetches a request_id for fetching random words from VRF. this will be used in next step
- call **reveal** with request_id retrieved previous step
- User metadata will be revealed! The reveal method will automatically be done via the one built into whatever contract the Owner
  inherited from above choices. Make sure the tx has enough gas -- fetching from VRF, *especially* is the numWords
  (total number of random values being generated and returned) is sufficiently large enough. If reverts, resend tx with more gas
- Note: it was an intentional design choice to separate **initiate_reveal_request** and **reveal** into separate calls, to allow for time between
  requesting random words from VRF and then checking status on that request. sometimes fulfilling a VRF request on the Chainlink side takes a bit of time.
- User may have to retry their **reveal** tx more than once. Creating a more streamlined system for this to assure retries are handled more seamlessly is an
  area of future improvement. For this demo, it felt preferable to do it this way instead of having a while loop call **get_random_words** over and over until
  a fulfilled random words array is returned. This also is a way to throttle traffic a bit, and having while loops to handle retries would certainly result in
  a lot of User tx's running out of gas

**NFTInternalCollectionRevealer_mockedVRF**/**NFTExternalCollectionRevealer_mockedVRF**
- these contract implementations are just for testing purposes. The Hardhat unit tests of core functionalities for
  **NFTInternalCollectionRevealer**/**NFTExternalCollectionRevealer** contracts are tested via this mock contracts to be
  able to test core functions without relying on real VRF interactions

**Sepolia testnet deployments**
**NFTInternalCollectionRevealer**: 0x6988F08D936000E288B6e8b8Ac8F23Ae6DCDC0Ae
**NFTExternalCollectionRevealer**: 0x4Fb5a6681847ab8e34070c2465F37595Cf69d8A0
**VRFv2Consumer**: 0x8d99F109087893418e185C7011686804F75Fd8c6

**Run tests:**
npm i hardhat
npx hardhat test (in root)
