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
   
 - add commandline examples to inline documentation (see code from
   the `bridge module`_)
 - make OVS module State-aware
 - build formula to move configuration (IP addr etc.) from interface 
   used as uplink to given OVS-bridge
 - identify packages on different distributions and update map.jinja 
   acordingly
 - define a bool for kernel module via DKMS or not on Debian/Ubuntu
 - make ovs_bridge.show() return a real dict not just txt resambling
   YAML/JSON
 - eventually move module from using cmdline tools to OVS' JSON RPC 
   interface (probably based on code from OpenStack's Neutron)

.. _bridge module: https://github.com/saltstack/salt/blob/develop/salt/modules/bridge.py

Mostly done:
 - implement OVS module for SaltStack (using the `ovs-*` commandline
   tools):

    - create/delete/check for bridges
    - assign interfaces as ports

Available states
================

.. contents::
    :local:

``openvswitch``
---------------

Installs the packages for openvswitch and starts the associated services 
though not distribution aware yet (probably won't work on RHEL/CentOS/etc.)
