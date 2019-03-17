const deployDAOFactory = require('@aragon/os/scripts/deploy-daofactory.js')
const KreditsKit = artifacts.require('KreditsKit')

const ensAddr = process.env.ENS

module.exports = async (callback) => {
  if (!ensAddr) {
    callback(new Error("ENS address not found in environment variable ENS"))
  }

  const { daoFactory } = await deployDAOFactory(null, { artifacts, verbose: false })

  const kreditsKit = await KreditsKit.new(daoFactory.address, ensAddr)
  console.log(kreditsKit.address)

  kreditsKit.newInstance().then((ret) => {
    console.log(ret);
    callback();
  }).catch((e) => {
    console.log(e);
  })

}
