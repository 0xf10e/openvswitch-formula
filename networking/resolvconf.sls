{% if grains['os_family'] == 'Debian' %}
  {# Try to trigger update of /etc/resolv.conf on  #}
  {# changes if resolvconf is currently installed: #}
  {% if salt['pkg.version']('resolvconf') %}
resolvconf:
  service.running:
    - require:
      - file: /etc/resolvconf/resolv.conf.d
    - watch:  
      - file: /etc/resolvconf/resolv.conf.d
  {% endif %}
  {# Prepare the configfiles for resolvconf #}
  {# even if currently not installed: #}
 
/etc/resolvconf/resolv.conf.d:
  file.directory:
    - user: root
    - group: root
    - mode: 0755

/etc/resolv.conf:
  cmd.wait:
    - name: cat /etc/resolvconf/resolv.conf.d/head /etc/resolvconf/resolv.conf.d/base /etc/resolvconf/resolv.conf.d/tail | tee /etc/resolv.conf
    - watch:
      - file: /etc/resolvconf/resolv.conf.d/head
      - file: /etc/resolvconf/resolv.conf.d/base
      - file: /etc/resolvconf/resolv.conf.d/tail

  {% for file in ['head','base','tail'] %}
  {# These use 'servers', 'options' and 'domains' under pillar['dns']: #}
  {# (And the first one defaults to ['8.8.8.8'] #}
  {#  if pillar['dns:servers'] is empty) #}
/etc/resolvconf/resolv.conf.d/{{file}}:
  file.managed:
    - source: salt://networking/files/resolv.conf.d_{{file}}
    - user: root
    - group: root
    - mode: 0444
    - template: jinja
  {% endfor%}

{# always true on non-Debian-derived Linux: #}
{% elif grains.os != 'Linux' or ( grains.os == 'Linux' and not salt['pkg.version']('resolvconf') ) %}
/etc/resolv.conf:
  file.managed:
    - source: salt://networking/resolv.conf
    - user: root
    - mode: 0444
    - template: jinja
{% endif %}
