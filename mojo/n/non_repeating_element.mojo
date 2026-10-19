from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("non_repeating_element")
fn non_repeating_element(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>64 or n%2!=0:return -1
    var total:Int32=0
    for i in range(Int(n)):
        if a[i]<0 or a[i]>1073741823:return -1
        total=total^Int32(a[i])
    if total==0:return -1
    let bit=total & -total
    var one:Int32=0;var two:Int32=0
    for i in range(Int(n)):
        let x=Int32(a[i])
        if (x&bit)!=0:one=one^x
        else:two=two^x
    return (Int64(one)<<32)|Int64(two)
