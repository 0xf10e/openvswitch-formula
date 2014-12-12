{% from "openvswitch/map.jinja" import openvswitch with context %}

openvswitch:
  pkg:
    - installed
    - name: {{ openvswitch.pkg }}
  service:
    - running
    - name: {{ openvswitch.service }}
    - enable: True
{# currently this module won't build on Ubuntu 14.04: #}
{% if salt['grains.get']('os') == 'Ubuntu' and salt['grains.get']('osrelease') < 14.04 %}
  kmod.present:
    - persist=True
    - requite:
      - pkg: openvswitch-datapath-dkms

openvswitch-datapath-dkms:
  pkg.installed 
{% endif %}


{% for bridge, config in salt['pillar.get']('openvswitch:bridges',{}).iteritems() %}
configure {{ bridge }}:
  ovs_bridge:
    - managed
    - name: {{ bridge }}
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
     {% set netcfg = salt['pillar.get']('interfaces:{0}'.format(uplink_iface)) %}
  {#- require:
      - network: {{ uplink_iface }} #}
  {#  - module: ovs_bridge #}
    {% if netcfg.has_key('v4addr') %}
  cmd.run:
    - name: ip addr add {{ netcfg['v4addr'] }} dev {{ bridge }}
    - require:
      - ovs_bridge: configure {{ bridge }}
      {% if netcfg.has_key('default_gw') and netcfg.has_key('primary') %}
        {% if netcfg['primary'] %}
set gateway on {{ bridge }}:
  cmd.run:
    - name: ip route change default via {{ netcfg['default_gw'] }} # {{ salt['network.interfaces']()[uplink_iface] }}
    - require: 
      - cmd: configure {{ bridge }}
        {% endif %}
      {% endif %}
      {% if salt['network.interfaces']().has_key(uplink_iface) and 
        salt['network.interfaces']()[uplink_iface].has_key('inet') %}
        {% if netcfg['v4addr'].split('/')[0] == salt['network.interfaces']()[uplink_iface]['inet'][0]['address'] %}
strip netcfg from {{ uplink_iface }}:
  cmd.run:
    - name: ip link set promisc on dev {{ uplink_iface }} && ip addr del {{ netcfg['v4addr'] }} dev {{ uplink_iface }}
    - require:
      - ovs_bridge: configure {{ bridge }}
      - cmd: configure {{ bridge }}
        {% endif %}
      {% endif %}
    {% endif %}
  {% endif %}
{% endfor %}
