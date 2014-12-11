#!py

def quaddot2int(quaddot):
    (a, b, c, d) = quaddot.split('.')
    result  = int(a) << 24
    result += int(b) << 16
    result += int(c) <<  8
    result += int(d)
    return result

def int2quaddot(num):
    # There's a prettier way to to this, right?
    a = (num & 0xff000000) >> 24
    b = (num & 0x00ff0000) >> 16
    c = (num & 0x0000ff00) >>  8
    d = (num & 0x000000ff)
    return '{0}.{1}.{2}.{3}'.format(a,b,c,d)

def netmask2prefixlen(netmask):
    '''
    Takes a netmask like '255.255.255.0'
    and returns a prefix length like '24'.
    '''
    netmask = netmask.split('.')
    bitmask = 0
    for idx in range(3, -1, -1):
        bitmask += int(netmask[idx]) << (idx * 8)
    prefixlen = format(bitmask, '0b').count('1')
    return '{0}'.format(prefixlen)

def prefixlen2netmask(prefixlen):
    return int2quaddot( 2**32 - 2** ( 32 - int(prefixlen) ))

def cidr2broadcast(cidr):
    netmask = prefixlen2netmask(cidr.split('/')[1])
    netmask_int = quaddot2int(netmask)
    addr_int = quaddot2int(cidr.split('/')[0]) 
    network_int = addr_int & netmask_int
    broadcast_int = network_int | (netmask_int ^ 0xFFFFFFFF)
    return int2quaddot(broadcast_int)

def cidr2network_options(cidr,settings={}):
  netmask = prefixlen2netmask(cidr.split('/')[1])
  new_settings = {}
  new_settings['v4addr'] = cidr
  new_settings['netmask'] = netmask
  new_settings['network'] = "{0}/{1}".format(
    int2quaddot(
        quaddot2int(cidr.split('/')[0]) & quaddot2int(netmask)),
    cidr.split('/')[1])
  new_settings['broadcast'] = cidr2broadcast(cidr)
  return new_settings

def run():
  state = {}
  # REWRITE:
  # 1st: Iterate over bridges and add the existing ones
  #      with config-data from their reuse_netcfg to the
  #      dict 'interfaces'.
  # 2nd: Iterate over interfaces and check which are not
  #      listed in a interfaces[bridge]['uplink']. 
  #      Add the remaining interfaces to the dict interfaces.

  if salt['pillar.get']('interfaces', False):
      if not 'ovs_bridge.exists' in salt:
        # Module ovs_bridge not available on this minion
        interfaces = {}
        for iface, settings in salt['pillar.get']('interfaces', {}).items():
          if settings.has_key('v4addr') and settings['v4addr'] != 'dhcp':
            interfaces[iface] = cidr2network_options(settings['v4addr'], settings)
        state['no module ovs_bridge'] = { 
                'cmd.run': {'name': 
                    'echo function ovs_bridge.exists missing' }
                }
      elif not salt['pillar.get']('openvswitch:bridges', False):
        interfaces = {}
        for iface, settings in salt['pillar.get']('interfaces', {}).items():
          if settings.has_key('v4addr') and settings['v4addr'] != 'dhcp':
            interfaces[iface] = cidr2network_options(settings['v4addr'], settings)
      else:
        interfaces = {}
        for bridge, br_config in salt['pillar.get'](
            'openvswitch:bridges', {}).items():
          if salt['ovs_bridge.exists'](bridge) and br_config.has_key('reuse_netcfg'):
            interfaces[bridge] = {}
            # TODO: Check if this interface exists!
            iface_config = salt['pillar.get'](
                'interfaces:{0}'.format(br_config['reuse_netcfg']))
            if iface_config.has_key('v4addr'):
              cidr = iface_config['v4addr']
              interfaces[bridge] = cidr2network_options(cidr, iface_config)
            if br_config.has_key('comment'):
              interfaces[bridge]['comment'] = br_config['comment']
            interfaces[bridge]['uplink'] = br_config['reuse_netcfg']
            if iface_config.has_key('comment'):
              interfaces[bridge]['uplink_comment'] = iface_config['comment']
#           # TODO: IPv6 config
#            if settings.has_key('v6addr'):
#              interfaces[bridge]['v6addr'] = salt['pillar.get'](
#                  'interfaces:{0}:v6addr'.format(iface))
        # get a list of all interfaces used as uplinks...:
        uplinks = []
        for br_conf in interfaces.values():
          if br_conf.has_key('uplink'):
            uplinks += [ br_conf['uplink'] ]
        # ...and interfaces not in this list will be passed
        # to the template for /etc/network/interfaces:
        for iface, settings in salt['pillar.get']('interfaces', {}).items():
          if iface not in uplinks:
            interfaces[iface] = settings
            # TODO: Get this comment back in there:
            #interfaces[iface]['comment'] = \
            #      "Bridge {0} doesn't exist yet".format(bridge)
            if settings.has_key('v4addr'):
              cidr = salt['pillar.get'](
                  'interfaces:{0}:v4addr'.format(iface))
              interfaces[iface] = cidr2network_options(cidr, settings)
            if settings.has_key('comment'):
              interfaces[iface]['comment'] = settings['comment']
              

      state['/etc/network/interfaces'] = {
        'file.managed': [
            {'source': 'salt://networking/network_interfaces.jinja'},
            {'template': 'jinja'},
            {'defaults': {
                'subnets': salt['pillar.get']('subnets'),
                'interfaces': interfaces,
                    }
                },
            {'require_in': [ 'neutron.openvswitch' ]},
          ]
        }
  return state

# make sure we got /some/ nameserver configured:
#{% if not salt['file.search'](
#        '/etc/resolv.conf', 'nameserver {0}'.format(
#            salt['pillar.get'](
#                'dns:servers', ['8.8.8.8']
#            )[0]
#        )) %}
#add nameserver(s) to /etc/resolv.conf:
#  file.append:
#    - name: /etc/resolv.conf
#    - text: 
#  {%- for server in salt['pillar.get']('dns:servers',['8.8.8.8']) %}
#        - nameserver {{ server }}
#  {%- endfor %}
#{%- endif %}
