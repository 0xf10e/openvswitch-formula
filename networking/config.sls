{% if salt['pillar.get']('interfaces', False) %}
  {% if grains['os_family'] == 'Debian' %}
/etc/network/interfaces:
  file.managed:
    - source: salt://networking/network_interfaces.jinja
    - template: jinja
    - require:
      - pkg: python-netaddr
    {#- module: net_addr#}

python-netaddr:
  pkg.installed
  {% endif %}
{% endif %}
