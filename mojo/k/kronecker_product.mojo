from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kronecker_product")
fn kronecker_product(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=6:return -1
    var out:Int64=0
    for i in range(2):
        for j in range(2):
            let av=a[2*i+j]
            if av< -10 or av>10:return -1
            for k in range(2):
                let bv=a[4+k]
                if bv< -10 or bv>10:return -1
                let value=av*bv
                out=out*201+(value+100)
    return out
