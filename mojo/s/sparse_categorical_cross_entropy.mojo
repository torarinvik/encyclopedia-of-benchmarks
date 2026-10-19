from std.ffi import c_size_t
from std.math import log
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64= -1.0e300
@export("sparse_categorical_cross_entropy")
fn sparse_categorical_cross_entropy(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return BAD
    let bv=v[0];let cv=v[1]
    if bv<1 or bv>32 or cv<1 or cv>32:return BAD
    let b=Int(bv);let c=Int(cv)
    if n!=c_size_t(2+b+b*c):return BAD
    for row in range(b):
        let label=v[2+row]
        if label<0 or label>=cv:return BAD
        var sum:Int64=0
        for col in range(c):
            let x=v[2+b+row*c+col]
            if x<0 or x>1000000:return BAD
            sum+=x
        if sum!=1000000:return BAD
    var total:Float64=0.0
    for row in range(b):
        let label=Int(v[2+row]);let x=Float64(v[2+b+row*c+label])/1000000.0
        let clipped=if x<1e-15 then 1e-15 else (if x>1.0 then 1.0 else x)
        total+= -log(clipped)
    return total
