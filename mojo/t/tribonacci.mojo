from std.memory import ImmutAnyOrigin, UnsafePointer
@export("tribonacci")
fn tribonacci(n:Int64) abi("C")->Int64:
    if n<0 or n>73:return -1
    if n==0:return 0
    if n<3:return 1
    var a:Int64=0;var b:Int64=1;var c:Int64=1
    for _ in range(3,Int(n)+1):let d=a+b+c;a=b;b=c;c=d
    return c
