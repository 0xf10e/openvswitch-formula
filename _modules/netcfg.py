'''
Little function turning a netmask into a CIDR prefix.

Would be great as custom filter in jinja, right?
'''
def netmask2prefix(netmask):
    '''
    Takes a netmask like '255.255.255.0' 
    and returns a prefix like '24'.
    '''
    n = 3
    sum = 0
    for el in netmask.split('.'):
        el = int(el)
        el = el << (n * 8)
        sum += el
        n -= 1
     
    prefix = format(sum,'0b').count('1')
    return '{0}'.format(prefix)
