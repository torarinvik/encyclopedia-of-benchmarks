@export("digital_root")
fn digital_root(n0:Int64) abi("C")->Int64:
    if n0<0:return -1
    var n=n0
    while n>=10:
        var total:Int64=0
        while n>0:total+=n%10;n/=10
        n=total
    return n
