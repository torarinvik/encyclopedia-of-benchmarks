"""Oracle for the pinned sort-and-count strict-majority routine."""
MAX_INPUT_LENGTH=128
def expected_result(values):
    if not isinstance(values,(list,tuple)) or not 2<=len(values)<=MAX_INPUT_LENGTH:return -1
    if any(type(x)is not int or not -(2**31)<=x<2**31 for x in values):return -1
    ordered=sorted(values);run=1
    for i in range(1,len(ordered)):
        run=run+1 if ordered[i]==ordered[i-1] else 1
        if run>len(ordered)//2:return ordered[i]
    return -1
