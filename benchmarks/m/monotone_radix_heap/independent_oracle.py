"""Unexecuted direct-multiset reference for the monotone queue contract."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 130
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or x < -(1 << 63) or x >= 1 << 63 for x in values)):
        return -1
    q=values[0]
    if q<0 or q>64 or len(values)!=1+2*q:
        return -1
    pending=[]
    last=0
    total=0
    count=0
    for index in range(q):
        op,key=values[1+2*index:3+2*index]
        if op==0 and last<=key<=2_147_483_647:
            pending.append(key)
        elif op==1 and key==0 and pending:
            last=min(pending)
            pending.remove(last)
            count+=1
            total+=count*last
        else:
            return -1
    return total
