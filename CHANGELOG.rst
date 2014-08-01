openvswitch-formula
===================

0.3.a (2014-08-01)

- Implemented a formula to create a OVS-base bridge reusing the
  network config of the uplink interface w/o taking the host
  offline. Not tested anywhere then Ubuntu 14.04 and assumes
  the netmask is 255.255.255.0 and you don't need to make
  the uplink promisc.

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
