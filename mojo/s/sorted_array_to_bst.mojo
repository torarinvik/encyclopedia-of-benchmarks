from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn bst_emit(a:InlineArray[Int64,64],start:Int,end:Int,out:UnsafePointer[UInt8,MutAnyOrigin],p:Int)->Int:
    if start==end:out[p]=0;return p+1
    let mid=start+(end-start-1)/2;out[p]=1;let bits=UInt32(Int32(a[mid]))
    for b in range(4):out[p+1+b]=UInt8((bits>>UInt(8*b))&255)
    let q=bst_emit(a,start,mid,out,p+5);return bst_emit(a,mid+1,end,out,q)
@export("sorted_array_to_bst")
fn sorted_array_to_bst(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>64 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var a=InlineArray[Int64,64](fill=0)
    for i in range(Int(n)):
        if v[i]< -2147483648 or v[i]>2147483647 or (i>0 and v[i-1]>=v[i]):return -1
        a[i]=v[i]
    let req=6*Int(n)+1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(req):return -2
    bst_emit(a,0,Int(n),o,0);return Int64(n)
