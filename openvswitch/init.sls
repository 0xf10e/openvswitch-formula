{% from "openvswitch/map.jinja" import openvswitch with context %}

openvswitch:
  pkg:
    - installed
    - name: {{ openvswitch.pkg }}
  service:
    - running
    - name: {{ openvswitch.service }}
    - enable: True
