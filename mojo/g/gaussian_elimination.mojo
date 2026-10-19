from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn ge2_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("gaussian_elimination")
fn gaussian_elimination(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<2 or v[0]>8:return -1
    let d=Int(v[0]);if n!=c_size_t(1+d*d+d):return -1
    var a=InlineArray[Float64,72](fill=0.0);let w=d+1
    for r in range(d):
        for c in range(d):
            let z=v[1+r*d+c]
            if (r==c and z!=32) or (r!=c and z!=0 and z!= -1) or ((r+1<c or c+1<r) and z!=0) or (r!=c and z!=v[1+c*d+r]):return -1
            a[r*w+c]=Float64(z)
        let rhs=v[1+d*d+r];if rhs< -100 or rhs>100:return -1;a[r*w+d]=Float64(rhs)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(d*8):return -2
    for step in range(d-1):
        for r in range(step+1,d):
            let f=a[r*w+step]/a[step*w+step]
            for c in range(step,d+1):a[r*w+c]-=f*a[step*w+c]
    var x=InlineArray[Float64,8](fill=0.0)
    for rev in range(d):
        let r=d-1-rev;var sum=0.0
        for c in range(r+1,d):sum+=a[r*w+c]*x[c]
        x[r]=(a[r*w+d]-sum)/a[r*w+r]
    for i in range(d):ge2_put(out,i*8,x[i])
    return Int64(d*8)
