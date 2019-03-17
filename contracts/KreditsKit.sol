pragma solidity 0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/kernel/Kernel.sol";
import "@aragon/os/contracts/acl/ACL.sol";

import "@aragon/kits-base/contracts/KitBase.sol";
import "./misc/APMNamehashOpen.sol";

import "../apps/contributions/contracts/Contributions.sol";
import "../apps/contributors/contracts/Contributors.sol";
import "../apps/token/contracts/Token.sol";

contract KreditsKit is KitBase, APMNamehashOpen {
    bytes32 public contributorsAppId = apmNamehash("contributors");
    bytes32 public contributionsAppId = apmNamehash("contributions");
    bytes32 public tokensAppId = apmNamehash("token");


    event DeployInstance(address dao);
    event InstalledApp(address dao, address appProxy, bytes32 appId);

    constructor (DAOFactory _fac, ENS _ens) KitBase(_fac, _ens) {}

    function newBareInstance() public returns (Kernel dao, ERCProxy proxy) {
        return newInstance(bytes32(0), new bytes32[](0), address(0), new bytes(0));
    }

    function newInstance(bytes32 appId, bytes32[] roles, address authorizedAddress, bytes initializeCalldata) public returns (Kernel dao, ERCProxy proxy) {
        address root = msg.sender;
        dao = fac.newDAO(this);
        ACL acl = ACL(dao.acl());

        acl.createPermission(this, dao, dao.APP_MANAGER_ROLE(), this);

        Contributors contributors = Contributors(_installApp(dao, contributorsAppId));
        contributors.initialize();
        acl.createPermission(root, contributors, contributors.MANAGE_CONTRIBUTORS_ROLE(), root);        
        
        Token token = Token(_installApp(dao, tokensAppId));
        token.initialize();
        acl.createPermission(root, token, token.MINT_TOKEN_ROLE(), root);        
        
        Contributions contributions = Contributions(_installApp(dao, contributionsAppId));
        contributions.initialize(token);

        acl.createPermission(root, contributions, contributions.ADD_CONTRIBUTION_ROLE(), root);        
        acl.createPermission(root, contributions, contributions.MANAGE_TOKEN_CONTRACT_ROLE(), root);        
        
        acl.createPermission(contributions, token, token.MINT_TOKEN_ROLE(), root);        


        cleanupDAOPermissions(dao, acl, root);

        emit DeployInstance(dao);
    }

    function _installApp(Kernel _dao, bytes32 _appId) internal returns (AragonApp) {
      address baseAppAddress = latestVersionAppBase(_appId);
      require(baseAppAddress != address(0), "App should be deployed");
      AragonApp appProxy = AragonApp(_dao.newAppInstance(_appId, baseAppAddress));

      emit InstalledApp(_dao, appProxy, _appId);
      return appProxy;
    }
}
