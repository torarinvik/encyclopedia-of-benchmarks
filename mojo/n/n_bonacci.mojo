from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("n_bonacci")
fn n_bonacci(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let order=a[0];let terms=a[1]
    if order<1 or order>=terms or terms>64:return -1
    var x=InlineArray[Int64,64]();x[Int(order)-1]=1
    for i in range(Int(order),Int(terms)):
        var s:Int64=0
        for j in range(i-Int(order),i):s+=x[j]
        x[i]=s
    return x[Int(terms)-1]
