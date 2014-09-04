===================
openvswitch-formula
===================

A saltstack formula for deploying OpenVSwitch_.

.. _OpenVSwitch: http://openvswitch.org/

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/topics/conventions/formulas.html>`_.

TODO
====
   
 - get network.get_route(iface=None,dest=None) into SaltStack so 
   we don't have to use a custom ``network``-module
 - add documentation for ``_modules/ovs_bridge``, ``_states/ovs_bridge``
   below
 - add commandline examples to inline documentation (see the official
   `bridge module's code`_)
 - ``ovs_brigde.managed(force=True)`` to remove an interface when it's
   bonded to the wrong bridge?
 - ``ovs_bridge.absent`` for an bridge that shouldn't exist?
 - identify packages on different distributions and update map.jinja 
   acordingly
 - define a bool for kernel module via DKMS or not on Debian/Ubuntu
 - make ovs_bridge.show() return a real dict not just txt that looks
   kinda like YAML (or JSON w/o curly braces)
 - eventually move module from using cmdline tools to OVS' JSON RPC 
   interface (probably based on code from OpenStack's Neutron)

.. _bridge module's code: 
   https://github.com/saltstack/salt/blob/develop/salt/modules/bridge.py


Available states
================

.. contents::
    :local:

``openvswitch``
---------------

Installs the packages for openvswitch and starts the associated services 
though not distribution aware yet (probably won't work on RHEL/CentOS/etc.).
Afterwards creates the bridges listed in ``pillar[openvswitch:bridges]``.
You can add list of interfaces to each bridge and those will be added as ports.
If the parameter ``clean`` is set to ``True`` any other interfaces are removed.
To re-use the configuration of a particular interface on the bridge set the
parameter ``reuse_netcfg`` to the name of the interface.

.. code-block:: yaml

    openvswitch:
      bridges:
        - ovs-br0:
            ports:
              - eth0
            reuse_netcfg: eth0
        - ovs-br1:
            ports:
              - eth1
              - eth2
              - eth3
            clean: True

``networking.config``
---------------------

Generates `/etc/network/interfaces` from ``pillar[interfaces]``, 
``pillar[subnets]`` and ``pillar[openvswitch:bridges]``. If an 
interface listed in ``pillar[interfaces]`` appears in a bridge's 
``reuse_netcfg`` key its configuration will be used for the bridge.
The interface itself will only get a minimal config to be set `up` 
and `promisc` on boot.

I.e. this pillar-data:

.. code-block:: yaml

    openvswitch:
      bridges:
        - ovs-br0:
            ports:
              - eth0
            reuse_netcfg: eth0
            comment: ovs-brigde for 10.10.0.0/16

    interfaces:
      eth0:
        comment: Uplink for ovs-br0
        v4addr: 10.10.0.5/16

    subnets: 
      10.10.0.0/16:
        gateway: 10.10.0.1

Would result in something like this in your `/etc/network/interfaces`::

    # ovs-brigde for 10.10.0.0/16
    auto ovs-br0
    iface ovs-br0 inet static
        address   10.10.0.5
        netmask       255.255.0.0
        network   10.10.0.0
        broadcast 10.10.255.255

    # Uplink for ovs-br0
    auto eth0
    iface eth0 inet manual
        post-up ip link set promisc on eth0
        pre-down ip link set promisc off eth0

Available modules
=================

.. contents::
    :local:

``_modules/ovs_bridge``
-----------------------
A module to manage OpenVSwitch bridges on supported Platforms (Linux and,
in theory, FreeBSD and NetBSD). Its functions mirror those of the official
`bridge module`_.

.. _bridge module: 
  http://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.bridge.html

``_states/ovs_bridge``
----------------------
State module to get your OVS-bridges in the state you want them to be.
