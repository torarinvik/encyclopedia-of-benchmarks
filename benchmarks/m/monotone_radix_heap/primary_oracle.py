"""Unexecuted monotone radix-bucket operation reference."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or not 1 <= len(values) <= 130
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    q=values[0]
    if not 0 <= q <= 64 or len(values)!=1+2*q:
        return -1
    buckets=[[] for _ in range(32)]
    last=0
    removed=0
    result=0
    for i in range(q):
        op,key=values[1+2*i:3+2*i]
        if op==0:
            if not last <= key <= 2_147_483_647:
                return -1
            buckets[(key ^ last).bit_length()].append(key)
        elif op==1 and key==0:
            if not buckets[0]:
                index=next((j for j in range(1,32) if buckets[j]),None)
                if index is None:
                    return -1
                last=min(buckets[index])
                pending=buckets[index]
                buckets[index]=[]
                for value in pending:
                    buckets[(value ^ last).bit_length()].append(value)
            value=buckets[0].pop()
            removed+=1
            result+=removed*value
        else:
            return -1
    return result
