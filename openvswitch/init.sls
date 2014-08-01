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
    - require:
      - ovs_bridge: {{ bridge }}

strip netcfg from {{ uplink_iface }}:
  cmd.run:
    - name: ip link set promisc on dev {{ uplink_iface }} && ip addr del {{ netcfg['inet'][0]['address'] }}/{{ salt['netcfg.netmask2prefix'](netcfg['inet'][0]['netmask']) }} dev {{ uplink_iface }}
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
