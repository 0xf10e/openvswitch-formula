'''
Little functions like turning a netmask into a CIDR prefix 
length (would be great as custom filter in jinja, right?).
'''
def netmask2prefixlen(netmask):
    '''
    Takes a netmask like '255.255.255.0' 
    and returns a prefix length like '24'.
    '''
    n = 3
    sum = 0
    for el in netmask.split('.'):
        el = int(el)
        el = el << (n * 8)
        sum += el
        n -= 1
     
    prefixlen = format(sum,'0b').count('1')
    return '{0}'.format(prefixlen)
