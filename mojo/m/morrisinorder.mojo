from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mi_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):o[p+ b]=UInt8((u>>(8*b))&255)
@export("morrisinorder")
fn morrisinorder(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65 or v[0]<0 or v[0]>63 or Int(n)!=1+Int(v[0]):return -1
    let count=Int(v[0]);var vals=InlineArray[Int32,63](fill=0);var right=InlineArray[Int64,63](fill=0)
    for i in range(count):if v[i+1] < -2147483648 or v[i+1]>2147483647:return -1;vals[i]=Int32(v[i+1]);right[i]=if 2*i+2<count:Int64(2*i+2) else:Int64(-1)
    let bytes=count*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var left=InlineArray[Int64,63](fill=0)
    for i in range(count):left[i]=if 2*i+1<count:Int64(2*i+1) else:Int64(-1)
    var cur=if count==0:Int64(-1) else:Int64(0);var written=0
    while cur>=0:
        let c=Int(cur)
        if left[c]<0:mi_put(o,4*written,vals[c]);written+=1;cur=right[c]
        else:
            var pred=Int(left[c])
            while right[pred]>=0 and right[pred]!=cur:pred=Int(right[pred])
            if right[pred]<0:right[pred]=cur;cur=left[c]
            else:right[pred]=-1;mi_put(o,4*written,vals[c]);written+=1;cur=right[c]
    return Int64(bytes)
