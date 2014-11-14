{% if salt['pillar.get']('interfaces', False) %}
  {% if grains['os_family'] == 'Debian' %}
/etc/network/interfaces:
  file.managed:
    - source: salt://networking/network_interfaces.jinja
    - template: jinja
    - defaults: 
        subnets: {{ salt['pillar.get']('subnets') }}
    {% if not 'ovs_bridge.exists' in salt %}
        # Module ovs_bridge not available on this minion
        interfaces: {{ salt['pillar.get']('interfaces') }}
    {% elif not salt['pillar.get']('openvswitch:bridges', False) %}
        interfaces: {{ salt['pillar.get']('interfaces') }}
    {% else %}
        interfaces:
      {% for iface, settings in salt['pillar.get']('interfaces', {}).items() %}
        {% for bridge in salt['pillar.get']('openvswitch:bridges', {}).keys() %}
          {% if iface == salt['pillar.get'](
                    'openvswitch:bridges:{0}:reuse_netcfg'.format(
                        bridge),
                    []) -%}
            {% if salt['ovs_bridge.exists'](bridge) %}
            {{ bridge }}:
              {% set br_comment = salt['pillar.get'](
                    'openvswitch:bridges:{0}:comment'.format(
                        bridge), 
                    False) %}
              {% if br_comment %}
                comment: {{ br_comment }}
              {% endif %}
              {% if settings.has_key('comment') %}
                uplink_comment: {{ salt['pillar.get'](
                    'interfaces:{0}:comment'.format(iface)) }}
              {% endif %}
              {% if settings.has_key('v4addr') %}
                v4addr: {{ salt['pillar.get'](
                    'interfaces:{0}:v4addr'.format(iface)) }}
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

# make sure we got /some/ nameserver configured:
{% if not salt['file.search'](
        '/etc/resolv.conf', 'nameserver {0}'.format(
            salt['pillar.get'](
                'dns:servers', ['8.8.8.8']
            )[0]
        )) %}
add nameserver(s) to /etc/resolv.conf:
  file.append:
    - name: /etc/resolv.conf
    - text: 
  {%- for server in salt['pillar.get']('dns:servers',['8.8.8.8']) %}
        - nameserver {{ server }}
  {%- endfor %}
{%- endif %}
