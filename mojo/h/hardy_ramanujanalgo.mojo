@export("hardy_ramanujanalgo")
fn hardy_ramanujanalgo(n0:Int64) abi("C")->Int64:
    if n0<1 or n0>2147483647:return -1
    var n=n0;var count:Int64=0
    if n%2==0:count+=1
    while n%2==0:n/=2
    var factor:Int64=3
    while factor<=n//factor:
        if n%factor==0:
            count+=1
            while n%factor==0:n/=factor
        factor+=2
    if n>2:count+=1
    return count
