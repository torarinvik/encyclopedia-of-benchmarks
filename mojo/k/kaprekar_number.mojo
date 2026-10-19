from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kaprekar_number")
fn kaprekar_number(x:Int64) abi("C")->Int64:
    if x<1:return 0
    if x>2000000000:return -1
    if x==1:return 1
    let sq=x*x;var p:Int64=10
    while p<=sq:
        let r=sq%p
        if r>0 and sq//p+r==x:return 1
        if p>sq//10:break
        p*=10
    return 0
