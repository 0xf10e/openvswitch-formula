===================
openvswitch-formula
===================

A saltstack formula for deploying OpenVSwitch_.

.. _OpenVSwitch: http://openvswitch.org/

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/topics/conventions/formulas.html>`_.

TODO
----
 
 - implement OVS module for SaltStack (using the `ovs-*` commandline
   tools):

    - create bridges
    - assign interfaces as ports
    - move configuration (IP addr etc.) from interface used 
      as uplink to OVS-bridge
   
 - identify packages on different distributions and update map.jinja 
   acordingly
 - define a bool for kernel module via DKMS or not on Debian/Ubuntu
 - make OVS module State-aware
 - eventually move module from using cmdline tools to OVS' JSON RPC 
   interface (probably based on code from OpenStack's Neutron)

Available states
================

.. contents::
    :local:

``openvswitch``
---------------

Installs the packages for openvswitch and starts the associated services.
