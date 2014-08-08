'''
Little functions like turning a netmask into a CIDR prefix 
length (would be great as custom filter in jinja, right?).

Also available as network.netmask_to_prefixlen in
https://github.com/0xf10e/salt
'''
def netmask2prefixlen(netmask):
    '''
    Takes a netmask like '255.255.255.0' 
    and returns a prefix length like '24'.
    '''
    netmask = netmask.split('.')
    bitmask = 0
    for idx in range(3, -1, -1):
        bitmask += int(netmask[idx]) << (idx * 8)
    prefixlen = format(bitmask, '0b').count('1')
    return '{0}'.format(prefixlen)
