@export("mobius_function")
fn mobius_function(n:Int64) abi("C")->Int64:
    if n<1 or n>10000:return -9223372036854775808
    var rem=n;var factors=0;var f:Int64=2
    while f*f<=rem:
        if rem%f==0:
            rem/=f
            if rem%f==0:return 0
            factors+=1
        f+=1
    if rem>1:factors+=1
    return 1 if factors%2==0 else -1
