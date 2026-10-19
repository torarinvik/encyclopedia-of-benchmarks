from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("jaccard_distance")
fn jaccard_distance(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1.0e300
    let a=Int(v[0]);let b=Int(v[1]);if a<0 or a>64 or b<0 or b>64 or n!=c_size_t(2+a+b):return -1.0e300
    for i in range(a):if v[2+i]<32 or v[2+i]>126:return -1.0e300
    for j in range(b):if v[2+a+j]<32 or v[2+a+j]>126:return -1.0e300
    var inter=0;var uni=0
    for i in range(a):
        var seen=False
        for k in range(i):if v[2+k]==v[2+i]:seen=True
        if not seen:
            uni+=1
            for j in range(b):
                if v[2+i]==v[2+a+j]:inter+=1;break
    for j in range(b):
        var seen=False
        for k in range(j):if v[2+a+k]==v[2+a+j]:seen=True
        if not seen:
            var inside=False
            for i in range(a):if v[2+i]==v[2+a+j]:inside=True
            if not inside:uni+=1
    return 0.0 if uni==0 else 1.0-Float64(inter)/Float64(uni)
