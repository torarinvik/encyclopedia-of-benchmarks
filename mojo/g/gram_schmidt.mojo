from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gs_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)
@export("gram_schmidt")
fn gram_schmidt(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>18:return -1
    let rows=Int(v[0]);let dim=Int(v[1]);if rows<1 or rows>4 or dim<rows or dim>4 or n!=c_size_t(2+rows*dim):return -1
    var a=InlineArray[Float64,16](fill=0.0);var q=InlineArray[Float64,16](fill=0.0)
    for i in range(rows):
        for j in range(dim):
            let x=v[2+i*dim+j];if x< -1000 or x>1000 or (j<i and x!=0) or (j==i and (x<100 or x>1000)):return -1
            a[i*4+j]=Float64(x)/1000.0
    let bytes=rows*dim*8;if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for k in range(rows):
        for j in range(dim):q[k*4+j]=a[k*4+j]
        var projections=InlineArray[Float64,4](fill=0.0)
        for i in range(k):
            var dot=0.0;var norm=0.0
            for j in range(dim):dot+=a[k*4+j]*q[i*4+j];norm+=q[i*4+j]*q[i*4+j]
            let factor=dot/norm
            for j in range(dim):projections[j]+=q[i*4+j]*factor
        for j in range(dim):q[k*4+j]=a[k*4+j]-projections[j]
    for i in range(rows):
        for j in range(dim):gs_put(out,(i*dim+j)*8,q[i*4+j])
    return Int64(bytes)
