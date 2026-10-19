from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("jaccard_similarity")
fn jaccard_similarity(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1.0e300
    let a=Int(v[0]);let b=Int(v[1]);if a<0 or a>64 or b<0 or b>64 or (a==0 and b==0) or n!=c_size_t(2+a+b):return -1.0e300
    for i in range(a):
        let x=v[2+i];if x<32 or x>126:return -1.0e300
        for j in range(i):if v[2+j]==x:return -1.0e300
    for i in range(b):
        let x=v[2+a+i];if x<32 or x>126:return -1.0e300
        for j in range(i):if v[2+a+j]==x:return -1.0e300
    var inter=0
    for i in range(a):
        for j in range(b):if v[2+i]==v[2+a+j]:inter+=1;break
    return Float64(inter)/Float64(a+b-inter)
