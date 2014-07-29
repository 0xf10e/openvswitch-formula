'''
Manage OpenVSwitch bridges from Salt.

Based on the Apache licensed salt/modules/bridge.py.

:maintainer:    Florian Ermisch <florian.ermisch@fokus.fraunhofer.de>
:maturity:      new
:depends:       openvswitch-switch
:platform:      Linux,FreeBSD
'''

import salt.utils

def __virtual__():
    '''
    Confirm this module is supported by the OS and the system has
    required tools
    '''
    if salt.utils.which('ovs-vsctl'):
      return True
    return False


def test():
    '''
    Test ovs-bridge module.
    '''
    retcode = __salt__['cmd.retcode']('ovs-vsctl show')
    if retcode == 0:
        return True
    else:
        return False

def add(br):
    '''
    Add a OVS bridge.
    '''
    # Make sure we don't create None bridges
    retcode = __salt__['cmd.retcode']('ovs-vsctl add-br {0}'.format(str(br)))
    if retcode == 0:
        return True
    else:
        return False

def addif(br, iface):
    '''
    Add interface as port on given bridge.
    
    .. code-block:: bash
    
    salt '*' ovs_bridge.addif ovs-br0 eth0
    '''
    retcode = __salt__['cmd.retcode'](
            'ovs-vsctl add-port {0} {1}'.format(str(br),str(iface))
            )
    if retcode == 0:
        return True
    else:
        return False

def delete(br):
    '''
    Delete given OVS bridge.
    '''
    # Managed to create a None bridge, forcing str() to
    # get rid of those:
    retcode = __salt__['cmd.retcode']('ovs-vsctl del-br {0}'.format(str(br)))
    if retcode == 0 and not exists(str(br)):
        return True
    else:
        return False

def exists(br):
    '''
    Check if given OVS bridge exists.
    '''
    retcode = __salt__['cmd.retcode']('ovs-vsctl br-exists {0}'.format(br))
    if retcode == 0:
        return True
    # From `ovs-vsctl --help`:
    #     br-exists BRIDGE            exit 2 if BRIDGE does not exist
    elif retcode == 2:
        return False
    else:
        raise ValueError

def show():
    '''
    Run `ovs-vsctl show` and return output.
    '''
    return __salt__['cmd.run']('ovs-vsctl show')
