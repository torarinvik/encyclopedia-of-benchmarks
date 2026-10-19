@export("jacobsthal_number")
fn jacobsthal_number(n:Int64) abi("C")->Int64:
    if n<0 or n>64:return -1
    if n==0:return 0
    var a:Int64=0;var b:Int64=1
    for i in range(2,Int(n)+1):let c=b+2*a;a=b;b=c
    return b
