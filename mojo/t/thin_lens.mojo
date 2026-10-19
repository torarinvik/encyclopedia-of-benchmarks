from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("thin_lens")
fn thin_lens(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1.0e300
    let op=a[0];let x=a[1];let y=a[2]
    if x< -1000 or x>1000 or y< -1000 or y>1000:return -1.0e300
    if op==0:
        if x==0 or y==0 or x==y:return -1.0e300
        return 1.0/(1.0/Float64(x)-1.0/Float64(y))
    if op==1:
        if y==0:return -1.0e300
        return Float64(x)/Float64(y)
    if op==2:
        if y!=0:return -1.0e300
        return 1.0 if x>0 else 0.0
    return -1.0e300
