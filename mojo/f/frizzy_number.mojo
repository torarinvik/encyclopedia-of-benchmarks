@export("frizzy_number")
fn frizzy_number(base:Int64,n:Int64) abi("C")->Int64:
    if base<2 or base>10 or n<0 or n>1023:return -1
    var value=n;var power:Int64=1;var result:Int64=0
    while value>0:
        if value%2==1:result+=power
        value/=2
        if value>0:power*=base
    return result
