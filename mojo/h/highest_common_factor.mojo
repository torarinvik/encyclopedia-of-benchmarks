@export("highest_common_factor")
fn highest_common_factor(x:UInt64,y:UInt64) abi("C")->Int64:
    var a=x;var b=y
    if a==0:return Int64(b)
    if b==0:return Int64(a)
    while a!=b:
        if a>b:a-=b
        else:b-=a
    return Int64(a)
