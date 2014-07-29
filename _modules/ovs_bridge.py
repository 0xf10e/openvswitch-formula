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
    return true

def show():
    '''
    Run `ovs-vsctl show` and return output.
    '''
    return __salt__['cmd.run']('ovs-vsctl show')
