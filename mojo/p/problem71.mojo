from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn p71_gcd(a_in:Int64,b_in:Int64)->Int64:
    var a=a_in;var b=b_in
    while b!=0:let r=a%b;a=b;b=r
    return a
@export("problem71")
fn problem71(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1
    let tn=input[0];let td=input[1];let limit=input[2]
    if tn<1 or td<=tn or td>1000000 or limit<1 or limit>1000000 or p71_gcd(tn,td)!=1:return -1
    var bn=Int64(0);var bd=Int64(1)
    for d in range(1,Int(limit+1)):
        var n=Int64(d)*tn//td
        if Int64(d)%td==0:n-=1
        if n*bd>Int64(d)*bn:bn=n;bd=Int64(d)
    return bn
