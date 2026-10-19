@export("padovan_sequence")
fn padovan_sequence(n:Int64) abi("C")->Int64:
    if n<0 or n>156:return -1
    if n<=2:return 1
    var a:Int64=1;var b:Int64=1;var c:Int64=1;var r:Int64=0
    for _ in range(3,Int(n)+1):r=a+b;a=b;b=c;c=r
    return r
