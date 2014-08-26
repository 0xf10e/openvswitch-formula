{% if salt['pillar.get']('interfaces', False) %}
  {% set requires_linux_br = False %}
  {% set requires_ovs = False %}
  {% for iface in salt['pillar.get']('interfaces').keys() %}
    {% if iface.startswith('br') %}
      {% if salt['pillar.get']('interfaces:{0}:type'.format(iface)) == 'ovs' %}
        {% set requires_ovs = True %}
      {% elif salt['pillar.get']('interfaces:{0}:type'.format(iface)) == 'linux-bridge' %}
        {% set requires_linux_br = True %}
      {% endif %}
    {% endif %}
  {% endfor %}
  {% if grains['os_family'] == 'Debian' %}
/etc/network/interfaces:
  file.managed:
    - source: salt://networking/network_interfaces.jinja
    - saltenv: openvswitch
    - template: jinja
    - require:
      - pkg: python-netaddr
    {% if requires_ovs %}
      - pkg: openvswitch-switch
    {% endif %}
    {% if requires_linux_br %}
      - pkg: bridge-utils
    {% endif %}
    {#- module: net_addr#}

python-netaddr:
  pkg.installed

    {% if requires_ovs %}
openvswitch-switch:
  pkg.installed
    {% endif %}

    {% if requires_linux_br %}
bridge-utils:
  pkg.installed
    {% endif %}
  {% endif %}
{% endif %}
