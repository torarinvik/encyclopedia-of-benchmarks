from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn gs_put32(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:UInt32):
    for b in range(4):o[p+b]=UInt8((v>>UInt(8*b))&255)
fn gs_put64(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:Int64):
    let z=bitcast[UInt64](v)
    for b in range(8):o[p+b]=UInt8((z>>UInt(8*b))&255)
@export("generate_sub_sets")
fn generate_sub_sets(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>13:return -1
    let count=a[0]
    if count<0 or count>12 or n!=c_size_t(count+1):return -1
    for i in range(Int(count)):if a[i+1]< -9007199254740991 or a[i+1]>9007199254740991:return -1
    let subsets=1<<Int(count);let items=Int(count)*(subsets/2);let bytes=4+4*subsets+8*items
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    gs_put32(o,0,UInt32(subsets));var p=4
    for mask in range(subsets):
        var c=0
        for j in range(Int(count)):if (mask&(1<<j))!=0:c+=1
        gs_put32(o,p,UInt32(c));p+=4
        for j in range(Int(count)):if (mask&(1<<j))!=0:gs_put64(o,p,a[j+1]);p+=8
    return Int64(bytes)
