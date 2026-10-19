from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from std.math import abs

fn gj_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("gauss_jordan")
fn gauss_jordan(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>22:return -1
    let rows=Int(v[0]);let cols=Int(v[1]);if rows<1 or rows>4 or cols<1 or cols>4 or n!=c_size_t(2+rows*cols+rows):return -1
    var a=InlineArray[Float64,16](fill=0.0);var b=InlineArray[Float64,4](fill=0.0)
    for r in range(rows):
        for c in range(cols):let z=v[2+r*cols+c];if z< -5000 or z>5000:return -1;a[r*4+c]=Float64(z)/1000.0
        let z=v[2+rows*cols+r];if z< -5000 or z>5000:return -1;b[r]=Float64(z)/1000.0
    let words=rows*cols+rows;let bytes=words*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for col in range(cols):
        var pivot= -1
        for r in range(col,rows):if abs(a[r*4+col])>1.0e-8:pivot=r;break
        if pivot<0:continue
        if pivot!=col:
            for c in range(cols):let t=a[col*4+c];a[col*4+c]=a[pivot*4+c];a[pivot*4+c]=t
            let t=b[col];b[col]=b[pivot];b[pivot]=t
        let pv=a[col*4+col]
        for c in range(cols):a[col*4+c]/=pv
        b[col]/=pv
        for r in range(rows):
            if r==col:continue
            let f=a[r*4+col]
            for c in range(cols):a[r*4+c]-=f*a[col*4+c]
            b[r]-=f*b[col]
    var at=0
    for r in range(rows):
        for c in range(cols):gj_put(out,at*8,a[r*4+c]);at+=1
    for r in range(rows):gj_put(out,at*8,b[r]);at+=1
    return Int64(bytes)
