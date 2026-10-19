from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn diff_array_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("difference_array")
fn difference_array(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2:return -1
    let nv=input[0];let qv=input[1]
    if nv<1 or nv>64 or qv<0 or qv>64 or length!=c_size_t(2+nv+3*qv):return -1
    let n=Int(nv);let q=Int(qv)
    for i in range(n):if input[2+i]< -1000000 or input[2+i]>1000000:return -1
    for u in range(q):
        let p=2+n+3*u
        if input[p]<0 or input[p]>=nv or input[p+1]<input[p] or input[p+1]>=nv or input[p+2]< -1000000 or input[p+2]>1000000:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(n*8):return -2
    var diff=List[Int64](length=n+1,fill=0);diff[0]=input[2]
    for i in range(1,n):diff[i]=input[2+i]-input[1+i]
    for u in range(q):
        let p=2+n+3*u;let l=Int(input[p]);let r=Int(input[p+1]);let delta=input[p+2]
        diff[l]+=delta;diff[r+1]-=delta
    var current=diff[0];diff_array_put(out,0,current)
    for i in range(1,n):current+=diff[i];diff_array_put(out,i*8,current)
    return Int64(n*8)
