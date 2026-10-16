"""Oracle for the pinned recursive binary peak finder."""
MAX_INPUT_LENGTH=129
def expected_result(values):
    if not isinstance(values,(list,tuple)) or not 2<=len(values)<=MAX_INPUT_LENGTH:return -1
    if any(type(x)is not int or not -(2**63)<=x<2**63 for x in values):return -1
    n=values[0]
    if not 1<=n<=128 or len(values)!=n+1 or any(not -(2**31)<=x<2**31 for x in values[1:]):return -1
    a=values[1:]
    lo=0;hi=n-1
    while lo<=hi:
        mid=(lo+hi)//2
        left=(mid==0 or a[mid-1]<=a[mid]);right=(mid==n-1 or a[mid+1]<=a[mid])
        if left and right:return mid
        if mid>0 and a[mid-1]>a[mid]:hi=mid-1
        else:lo=mid+1
    return -1
