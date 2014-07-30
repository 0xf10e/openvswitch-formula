openvswitch-formula
===================

0.2 (2014-07-30)

- Implemented a state modul to create bridges, add ports
  and optionally also remove ports not listed.

0.1 (2014-07-30)

- Initial version, implemented following functions in module
  (not state) 'ovs_bridge':

    - add(br)
    - addif(br, iface)
    - delete(br)
    - delif(br, iface)
    - exists(br)
    - interfaces(br)
    - find_interfaces(\*ifaces)
    - list()
    - show()
    - test()

0.0 (2014-07-28)

- Basic repository structure.
