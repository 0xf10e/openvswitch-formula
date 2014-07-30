# -*- coding: utf-8 -*-
'''
Operations on OpenvSwitch Bridges
=================================

'''
# Import python libs
import logging
import pprint
import yaml

# Import salt libs
import salt.utils
import salt.utils.templates
from salt.exceptions import CommandExecutionError

def managed(name,create=True,ports=[],clean=False):
    '''
    Ensure a OpenVSwitch based bridge existe and optionally has
    a list of interfaces as ports assigned.
    '''
    ret = {'name': name,
       'changes': {},
       'result': True,
       'comment': ''}

    if not __salt__['ovs_bridge.exists'](name):
        __salt__['ovs_bridge.add'](name)
        ret['changes'][name] = 'New ovs_bridge'

    for iface in ports:
        if __salt__['ovs_bridge.addif'](name, iface):
            ret['changes'][iface] = 'Added to bridge "{0}"'.format(name)
        else:
            ret['result'] = False
            ret['comment'] = 'Failed to add one or more ports to '\
                            'bridge "{0}"'.format(name)
    if not clean:
        return ret

    for iface in __salt__['ovs_bridge.interfaces'](name):
        if iface not in ports:
            if __salt__['ovs_bridge.delif'](name, iface):
                ret['changes'][iface] = 'Deleted from bridge "{0}"'\
                                        ''.format(name)
            else:
                ret['result'] = False
                ret['comment'] = 'Failed to del one or more ports'\
                                'from bridge "{0}"'.format(name)
    return ret
    
