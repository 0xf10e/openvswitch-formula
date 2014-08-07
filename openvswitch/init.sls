{% from "openvswitch/map.jinja" import openvswitch with context %}

openvswitch:
  pkg:
    - installed
    - name: {{ openvswitch.pkg }}
  service:
    - running
    - name: {{ openvswitch.service }}
    - enable: True

{% for bridge, config in salt['pillar.get']('openvswitch:bridges',{}).iteritems() %}
{{ bridge }}:
  ovs_bridge:
    - managed
  {% if config.has_key('clean') and config.clean %}
    - clean: True
  {% endif %}
  {% for port in salt['pillar.get']('openvswitch:bridges:'+ bridge + ':ports',[]) %}
    {% if loop.first %}
    - ports:
    {% endif %}
      - {{ port }}
  {% endfor %}
  {% set reuse_pillar = 'openvswitch:bridges:'+bridge+':reuse_netcfg' %}
  {% set uplink_iface = salt['pillar.get'](reuse_pillar, False) %}
  {% if uplink_iface %}
     {% set netcfg = salt['network.interfaces']()[uplink_iface] %}
     {% set def_route = salt['network.get_route'](dest='default',iface=uplink_iface) %}
  {#- require:
      - network: {{ uplink_iface }} #}
  {#  - module: ovs_bridge #}
    {% if netcfg.has_key('inet') %}
  network.managed:
    - enabled: True
    - type: eth
    - proto: none
    - ipaddr: {{ netcfg['inet'][0]['address'] }}
    - netmask: {{ netcfg['inet'][0]['netmask'] }}
    - broadcast: {{ netcfg['inet'][0]['broadcast'] }}
      {% if def_route != [] %}
    - gateway: {{ def_route[0]['gateway'] }}
      {% endif %}
    - require:
      - ovs_bridge: {{ bridge }}

strip netcfg from {{ uplink_iface }}:
  cmd.run:
      {% if 'netcfg.netmask2prefixlen' in salt['sys.list_functions']('network') %}
        {% set prefixlen = salt['netcfg.netmask2prefixlen'](netcfg['inet'][0]['netmask']) %}
      {% elif 'network.netmask_to_prefixlen' in salt['sys.list_functions']('network') %}
        {% set prefixlen = salt['network.netmask_to_prefixlen'](netcfg['inet'][0]['netmask']) %}
      {% endif %}
    - name: ip link set promisc on dev {{ uplink_iface }} && ip addr del {{ netcfg['inet'][0]['address'] }}/{{ prefixlen }} dev {{ uplink_iface }}
    - require:
      - ovs_bridge: {{ bridge }}
      - network: {{ bridge }}
  network.managed:
    - name: {{ uplink_iface }}
    - enabled: True
    - type: eth
    - proto: manual
    {% endif %}
  {% endif %}
{% endfor %}
