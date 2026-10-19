from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("mutate")
fn mutate(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<2 or n>130:return -1
    let mu=v[0];let count=Int(v[1]);if not is_finite(mu) or mu<0.0 or mu>1.0 or not is_finite(v[1]) or v[1]!=Float64(count) or count<0 or count>64 or Int(n)!=2+2*count:return -1
    for i in range(count):if v[2+i]!=0.0 and v[2+i]!=1.0:return -1
    for i in range(count):if not is_finite(v[2+count+i]) or v[2+count+i]<0.0 or v[2+count+i]>=1.0:return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):o[i]=1.0-v[2+i] if v[2+count+i]<mu else v[2+i]
    return Int64(count)
