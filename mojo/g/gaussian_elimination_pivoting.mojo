from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from std.math import abs

fn gep_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("gaussian_elimination_pivoting")
fn gaussian_elimination_pivoting(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>21:return -1
    let d=Int(v[0]);if d<2 or d>4 or n!=c_size_t(1+d*(d+1)):return -1
    var a=InlineArray[Float64,20](fill=0.0);let w=d+1
    for r in range(d):
        for c in range(w):let z=v[1+r*w+c];if z< -10000 or z>10000:return -1;a[r*w+c]=Float64(z)/1000.0
    for col in range(d):
        for r in range(col,d):
            if abs(a[r*w+col])>abs(a[col*w+col]):
                for c in range(w):let t=a[col*w+c];a[col*w+c]=a[r*w+c];a[r*w+c]=t
        if abs(a[col*w+col])<1.0e-8:return -1
        if col!=0:
            let prior=col-1
            for r in range(col,d):
                let f=a[r*w+prior]/a[prior*w+prior]
                for c in range(w):a[r*w+c]-=f*a[prior*w+c]
    var x=InlineArray[Float64,4](fill=0.0)
    for rev in range(d):
        let col=d-1-rev;x[col]=a[col*w+d]/a[col*w+col]
        for r in range(col):a[r*w+d]-=a[r*w+col]*x[col]
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(d*8):return -2
    for i in range(d):gep_put(out,i*8,x[i])
    return Int64(d*8)
