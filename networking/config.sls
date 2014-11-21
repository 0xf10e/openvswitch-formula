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
    return int2quaddot( 2**32 - 2** ( 32 - prefixlen ))

def run():
  state = {}
  if salt['pillar.get']('interfaces', False):
    if grains['os_family'] == 'Debian':
      if not 'ovs_bridge.exists' in salt:
        # Module ovs_bridge not available on this minion
        interfaces = salt['pillar.get']('interfaces')
      elif not salt['pillar.get']('openvswitch:bridges', False):
        interfaces = salt['pillar.get']('interfaces')
      else:
        interfaces = {}
        for iface, settings in salt['pillar.get']('interfaces', {}).items():
          for bridge in salt['pillar.get']('openvswitch:bridges', {}).keys():
            if iface == salt['pillar.get'](
               'openvswitch:bridges:{0}:reuse_netcfg'.format(
                    bridge), []):
              if salt['ovs_bridge.exists'](bridge):
                interfaces[bridge] = {
                  'comment': salt['pillar.get'](
                        'openvswitch:bridges:{0}:comment'.format(
                            bridge), False) }
              if settings.has_key('comment'):
                interface[bridge]['uplink_comment'] = salt['pillar.get'](
                    'interfaces:{0}:comment'.format(iface))
              if settings.has_key('v4addr'):
                cidr = salt['pillar.get'](
                    'interfaces:{0}:v4addr'.format(iface))
                netmask = prefixlen2netmask(cidr.split('/')[1])
                interfaces[bridge]['v4addr'] = cidr
                interfaces[bridge]['netmask'] = netmask
                interfaces[bridge]['network'] = (
                    quaddot2int(cidr.split('/')[0]) & quaddot2int(netmask))
              if settings.has_key('v6addr'):
                interfaces[bridge]['v6addr'] = salt['pillar.get'](
                    'interfaces:{0}:v6addr'.format(iface))
              if settings.has_key('primary'):
                interfaces[bridge]['primary'] = salt['pillar.get'](
                    'interfaces:{0}:primary'.format(iface))
              interfaces[bridge]['uplink'] = iface 
            else:
              # bridge doesn't exist (yet) #}
              interfaces[iface] = settings
              if settings.has_key('v4addr'):
                cidr = salt['pillar.get'](
                    'interfaces:{0}:v4addr'.format(iface))
                netmask = prefixlen2netmask(cidr.split('/')[1])
                interfaces[iface]['v4addr'] = cidr
                interfaces[iface]['netmask'] = netmask
                interfaces[iface]['network'] = (
                    quaddot2int(cidr.split('/')[0]) & quaddot2int(netmask))

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
