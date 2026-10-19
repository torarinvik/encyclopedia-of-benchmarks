from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from std.math import abs

fn ge_round2(x:Float32)->Float64:
    let scaled=abs(Float64(x)*100.0)
    var whole=Int64(scaled)
    let frac=scaled-Float64(whole)
    if frac>0.5 or (frac==0.5 and whole%2!=0):whole+=1
    return (Float64(whole)/100.0) if x>=0.0 else -(Float64(whole)/100.0)

fn ge_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("gauss_elimination")
fn gauss_elimination(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<2 or v[0]>8:return -1
    let d=Int(v[0]);if n!=c_size_t(1+d*d+d):return -1
    var a=InlineArray[Float32,72](fill=0.0);let width=d+1
    for r in range(d):
        for c in range(d):
            let z=v[1+r*d+c];if z< -100 or z>100:return -1;a[r*width+c]=Float32(z)
        let rhs=v[1+d*d+r];if rhs< -100 or rhs>100:return -1;a[r*width+d]=Float32(rhs)
    for step in range(d-1):
        var pivot=step;var maximum=abs(Float64(a[step*width+step]))
        for r in range(step,d):
            let m=abs(Float64(a[r*width+step]));if maximum<m:maximum=m;pivot=r
        if maximum==0.0:return -1
        if pivot!=step:
            for c in range(d+1):let t=a[step*width+c];a[step*width+c]=a[pivot*width+c];a[pivot*width+c]=t
        for r in range(step+1,d):
            let factor= -(a[r*width+step]/a[step*width+step])
            for c in range(d+1):a[r*width+c]=a[r*width+c]+a[step*width+c]*factor
    if a[(d-1)*width+d-1]==0.0:return -1
    var x=InlineArray[Float32,8](fill=0.0)
    for rev in range(d):
        let r=d-1-rev;var sum:Float32=0.0
        for c in range(r+1,d):sum=sum+a[r*width+c]*x[c]
        x[r]=(a[r*width+d]-sum)/a[r*width+r]
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(d*8):return -2
    for i in range(d):ge_put(out,i*8,ge_round2(x[i]))
    return Int64(d*8)
