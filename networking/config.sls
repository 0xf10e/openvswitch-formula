#!mako|yaml
% if salt['pillar.get']('interfaces', False):
  % if grains['os_family'] == 'Debian':
/etc/network/interfaces:
  file.managed:
    - source: salt://networking/network_interfaces.jinja
    - template: jinja
    - defaults: 
        subnets: ${ salt['pillar.get']('subnets') }
    % if not salt['pillar.get']('openvswitch:bridges', False):
        interfaces: ${ salt['pillar.get']('interfaces') }
    % else:
        _comment: iterating over interfaces...
        interfaces:
      <% all_bridges = salt['pillar.get']('openvswitch:bridges', {}).keys() %>
      <% all_uplinks = [salt['pillar.get'](
                          'openvswitch:bridges:{0}:reuse_netcfg'.format(bridge),
                          None) for bridge in all_bridges] %>
      % for iface, settings in salt['pillar.get']('interfaces', {}).items():
        % if iface not in all_uplinks:
            ${iface}: ${settings}
            debug_${iface}: ${iface} is no uplink
        % else:
          <%
            wrong_bridges = []
            parent_bridge = None
            for bridge in all_bridges:
                reuse_iface = salt['pillar.get']('openvswitch:bridges:{0}:reuse_netcfg'.format(bridge), False)
                if iface == reuse_iface and salt['ovs_bridge.exists'](bridge):
                    parent_bridge = bridge
                    break
                else:
                    wrong_bridges += [ {bridge: reuse_iface} ]
            bridge = parent_bridge
          %>
          % if bridge:
            ${ bridge }:
            <% br_comment = salt['pillar.get'](
               'openvswitch:bridges:{0}:comment'.format(bridge), False) %>
            % if br_comment:
                comment: ${ br_comment }
            % endif
            % if settings.has_key('comment'):
                uplink_comment: ${ salt['pillar.get'](
                                       'interfaces:{0}:comment'.format(iface)) }
            % endif
            % if settings.has_key('v4addr'):
                v4addr: ${ salt['pillar.get'](
                               'interfaces:{0}:v4addr'.format(iface)) }
            % endif
            % if settings.has_key('v6addr'):
                v6addr: ${ salt['pillar.get'](
                               'interfaces:{0}:v6addr'.format(iface)) }
            % endif
            % if settings.has_key('primary'):
                primary: ${ salt['pillar.get'](
                                'interfaces:{0}:primary'.format(iface)) }
            % endif
                uplink: ${ iface }
          % else:
            ${ iface }: ${ settings }
            debug_${ iface }: "${ wrong_bridges } of ${ all_bridges } don't have ${iface} as uplink"
          % endif 
        % endif 
      % endfor
    % endif
    - require:
      - pkg: python-netaddr
    - require_in:
      - neutron.openvswitch
    ##- module: net_addr

python-netaddr:
  pkg.installed
  % endif
% endif 
