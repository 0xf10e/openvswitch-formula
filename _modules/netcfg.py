'''
Little functions like turning a netmask into a CIDR prefix 
length (would be great as custom filter in jinja, right?).

Also available as network.netmask_to_prefixlen in
https://github.com/0xf10e/salt
'''
def quaddot2int(quaddot):
    (a, b, c, d) = quaddot.split('.')
    result  = int(a) << 24
    result += int(b) << 16
    result += int(c) <<  8
    result += int(d)
    return result

def int2quaddot(num):
    # There's a prettier way to to this, right?
    a = (num & 0xff000000) >> 24
    b = (num & 0x00ff0000) >> 16
    c = (num & 0x0000ff00) >>  8
    d = (num & 0x000000ff)
    return '{0}.{1}.{2}.{3}'.format(a,b,c,d)

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

def prefixlen2netmask(prefixlen):
    return int2quaddot( 2**32 - 2** ( 32 - prefixlen ))
