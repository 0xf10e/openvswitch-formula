include:
  - networking.config

networking service:
  service.running:
    - name: networking
{% if salt['grains.get']('os_family') == 'Debian' %}
    - full_restart: True
{% endif %}
    - watch: 
      # yes, I know, this makes no sense on non-Debian...
      - file: /etc/network/interfaces

# you can't "restart" the networking service on Debian and
# derivates (like Ubuntu) so run those commands instead:
{% for iface in salt['pillar.get']('interfaces', {}).keys() %}
  {% if iface in salt['grains.get']('hwaddr_interfaces').keys() %}
ifdown/ifup {{ iface }}:
  cmd.run:
    - name: "ifdown {{ iface }}; ifup {{ iface }}"
    - onfail:
      - service: networking
    - require: 
      - file: /etc/network/interfaces
    - watch: 
      - file: /etc/network/interfaces
  {% endif %}
{% endfor %}
