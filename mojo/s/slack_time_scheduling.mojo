from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sts_put(o:UnsafePointer[UInt8,MutAnyOrigin],off:Int,v:Int64):
    let b=UInt64(v);for i in range(8):o[off+i]=UInt8((b>>(i*8))&255)
@export("slack_time_scheduling")
fn slack_time_scheduling(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129:return -1
    let count=a[0];if count<0 or count>64 or n!=c_size_t(1+2*count):return -1
    var idx=InlineArray[Int32,64]();var slack=InlineArray[Int64,64]()
    for i in range(Int(count)):
        let e=a[1+2*i];let d=a[2+2*i];if e<0 or e>1000000 or d<0 or d>1000000:return -1
        idx[i]=Int32(i);slack[i]=d-e
    for i in range(1,Int(count)):
        let x=idx[i];var j=i
        while j>0 and slack[idx[j-1]]>slack[x]:idx[j]=idx[j-1];j-=1
        idx[j]=x
    let bytes=Int(count)*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(count)):sts_put(o,i*8,Int64(idx[i]))
    return bytes
