{% if salt['pillar.get']('interfaces', False) %}
  {% if grains['os_family'] == 'Debian' %}
/etc/network/interfaces:
  file.managed:
    - source: salt://networking/network_interfaces.jinja
    - template: jinja
    - defaults: 
        subnets: {{ salt['pillar.get']('subnets') }}
    {% if not salt['pillar.get']('openvswitch:bridges', False) %}
        interfaces: {{ salt['pillar.get']('interfaces') }}
    {% else %}
        interfaces:
      {% for iface, settings in salt['pillar.get']('interfaces', {}).items() %}
        {% for bridge in salt['pillar.get']('openvswitch:bridges', {}).keys() %}
          {% if iface in salt['pillar.get']('openvswitch:bridges:{0}:ports'.format(bridge),[]) -%}
            {% if salt['ovs_bridge.exists'](bridge) %}
            {{ bridge }}:
              {% if settings.has_key('comment') %}
                comment: {{ salt['pillar.get']('interfaces:{0}:comment'.format(iface)) }}
              {% endif %}
              {% if settings.has_key('v4addr') %}
                v4addr: {{ salt['pillar.get']('interfaces:{0}:v4addr'.format(iface)) }}
              {% endif %}
              {% if settings.has_key('v6addr') %}
                v6addr: {{ salt['pillar.get']('interfaces:{0}:v6addr'.format(iface)) }}
              {% endif %}
              {% if settings.has_key('primary') %}
                primary: {{ salt['pillar.get']('interfaces:{0}:primary'.format(iface)) }}
              {% endif %}
                uplink: {{ iface }}
            {% else %} {# bridge doesn't exist (yet) #}
            {{ iface }}: {{ settings }}
            {% endif %}
          {% endif %}
        {% endfor %}
      {% endfor %}
    {% endif %}
    - require:
      - pkg: python-netaddr
    - require_in:
      - neutron.openvswitch
    {#- module: net_addr#}

python-netaddr:
  pkg.installed
  {% endif %}
{% endif %}
