from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime MAX=3972
@export("stochastic_matrix")
fn stochastic_matrix(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>3972:return -1
    let mode=v[0];let rv=v[1];let cv=v[2]
    if (mode!=0 and mode!=1) or rv<1 or rv>63 or cv<1 or cv>63:return -1
    let rows=Int(rv);let cols=Int(cv);if n!=c_size_t(3+rows*cols):return -1
    for i in range(3,Int(n)):if v[i]< -1000000000000 or v[i]>1000000000000:return -1
    if mode==0:
        for r in range(rows):
            var sum=0.0
            for c in range(cols):
                let x=Float64(v[3+r*cols+c])/1e12
                if x<0:return 0
                sum+=x
            let d=sum-1.0
            if d>1e-9 or d< -1e-9:return 0
    else:
        for c in range(cols):
            var sum=0.0
            for r in range(rows):
                let x=Float64(v[3+r*cols+c])/1e12
                if x<0:return 0
                sum+=x
            let d=sum-1.0
            if d>1e-9 or d< -1e-9:return 0
    return 1
