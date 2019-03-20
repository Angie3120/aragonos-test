pragma solidity 0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/kernel/Kernel.sol";
import "@aragon/os/contracts/acl/ACL.sol";
import "@aragon/os/contracts/acl/ACLSyntaxSugar.sol";

import "@aragon/kits-base/contracts/KitBase.sol";
import "./misc/APMNamehashOpen.sol";

import "../apps/contributions/contracts/Contributions.sol";
import "../apps/contributors/contracts/Contributors.sol";
import "../apps/token/contracts/Token.sol";

contract KreditsKit is KitBase, APMNamehashOpen, ACLSyntaxSugar  {
    bytes32 public contributorsAppId = apmNamehash("contributors");
    bytes32 public contributionsAppId = apmNamehash("contributions");
    bytes32 public tokensAppId = apmNamehash("token");


    event DeployInstance(address dao);
    event InstalledApp(address dao, address appProxy, bytes32 appId);

    constructor (DAOFactory _fac, ENS _ens) KitBase(_fac, _ens) {}

    function newInstance() public returns (Kernel dao, ERCProxy proxy) {
        address root = msg.sender;
        dao = fac.newDAO(this);
        ACL acl = ACL(dao.acl());

        acl.createPermission(this, dao, dao.APP_MANAGER_ROLE(), this);

        Contributors contributors = Contributors(_installApp(dao, contributorsAppId));
        contributors.initialize();
        acl.createPermission(root, contributors, contributors.MANAGE_CONTRIBUTORS_ROLE(), root);
        
        Token token = Token(_installApp(dao, tokensAppId));
        token.initialize();
        
        Contributions contributions = Contributions(_installApp(dao, contributionsAppId));
        contributions.initialize(token);

        acl.createPermission(root, contributions, contributions.MANAGE_TOKEN_CONTRACT_ROLE(), root);
        
        acl.createPermission(root, contributions, contributions.ADD_CONTRIBUTION_ROLE(), this);

        uint256[] memory params = new uint256[](1);
        params[0] = uint256(203) << 248 | uint256(1) << 240 | uint240(contributors);
        
        acl.grantPermissionP(root, contributions, contributions.ADD_CONTRIBUTION_ROLE(), params);
        acl.setPermissionManager(root, contributions, contributions.ADD_CONTRIBUTION_ROLE());
        
        acl.createPermission(root, token, token.MINT_TOKEN_ROLE(), this);
        acl.grantPermission(contributions, token, token.MINT_TOKEN_ROLE());        
        acl.setPermissionManager(root, token, token.MINT_TOKEN_ROLE());



        cleanupDAOPermissions(dao, acl, root);

        emit DeployInstance(dao);
    }

    function _installApp(Kernel _dao, bytes32 _appId) internal returns (AragonApp) {
      address baseAppAddress = latestVersionAppBase(_appId);
      require(baseAppAddress != address(0), "App should be deployed");
      AragonApp appProxy = AragonApp(_dao.newAppInstance(_appId, baseAppAddress, new bytes(0), true));

      emit InstalledApp(_dao, appProxy, _appId);
      return appProxy;
    }
}
