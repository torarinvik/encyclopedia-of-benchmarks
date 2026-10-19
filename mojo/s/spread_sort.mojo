from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn spread_segment(a:UnsafePointer[Int32,MutAnyOrigin],start:Int,end:Int):
    let length=end-start
    if length<2:return
    if length<=16:
        for i in range(start+1,end):
            let key=a[i];var j=i
            while j>start and a[j-1]>key:a[j]=a[j-1];j-=1
            a[j]=key
        return
    var mn=a[start];var mx=a[start]
    for i in range(start+1,end):if a[i]<mn:mn=a[i];elif a[i]>mx:mx=a[i]
    if mn==mx:return
    var tmp=InlineArray[Int32,128](fill=0);var lo=0;var hi=0
    for i in range(start,end):if a[i]==mn:tmp[lo]=a[i];lo+=1
    hi=lo
    for i in range(start,end):if a[i]!=mn:tmp[hi]=a[i];hi+=1
    for i in range(end-start):a[start+i]=tmp[i]
    spread_segment(a,start+lo,end)
@export("spread_sort")
fn spread_sort(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>128 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var a=InlineArray[Int32,128](fill=0)
    for i in range(Int(n)):
        if v[i]< -2147483648 or v[i]>2147483647:return -1
        a[i]=Int32(v[i])
    if n==0:return 0
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(Int(n)*4):return -2
    spread_segment(a.unsafe_ptr(),0,Int(n))
    for i in range(Int(n)):let bits=bitcast[UInt32](a[i]);for b in range(4):o[i*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(Int(n)*4)
