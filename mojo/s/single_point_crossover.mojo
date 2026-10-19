from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("single_point_crossover")
fn single_point_crossover(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<6 or n>64:return -1
    let nv=a[0];let jv=a[1]
    if not (nv>=2.0 and nv<=31.0 and nv==Float64(Int(nv))) or not (jv>=1.0 and jv<nv and jv==Float64(Int(jv))):return -1
    let count=Int(nv);let cut=Int(jv);if n!=c_size_t(2+2*count):return -1
    for i in range(count*2):if not a[i+2].is_finite():return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count*2):return -2
    for i in range(count):
        o[i]=a[2+i] if i<cut else a[2+count+i]
        o[count+i]=a[2+count+i] if i<cut else a[2+i]
    return count*2
