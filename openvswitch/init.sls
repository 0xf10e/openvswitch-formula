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
  {#- require: #}
  {#  - module: ovs_bridge #}
{% endfor %}
