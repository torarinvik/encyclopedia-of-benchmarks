from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ml_put(out:UnsafePointer[UInt8,MutAnyOrigin],mut p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):out[p]=UInt8((u>>(8*b))&255);p+=1
@export("minimizing_lateness")
fn minimizing_lateness(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>64 or Int(n)!=1+2*Int(v[0]):return -1
    let count=Int(v[0]);var idx=InlineArray[Int64,64](fill=0);var proc=InlineArray[Int64,64](fill=0);var dead=InlineArray[Int64,64](fill=0);var total:Int64=0
    for i in range(count):
        let p=v[1+2*i];let d=v[2+2*i]
        if p<0 or p>2147483647 or d<0 or d>2147483647:return -1
        if total>2147483647-p:return -1
        total+=p;proc[i]=p;dead[i]=d;idx[i]=Int64(i)
    for i in range(1,count):
        let key=idx[i];var j=i
        while j>0 and dead[Int(idx[j-1])]>dead[Int(key)]:idx[j]=idx[j-1];j-=1
        idx[j]=key
    let bytes=4+count*12
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var p=0;ml_put(out,mut p,Int32(count));var time:Int64=0
    for i in range(count):
        let original=Int(idx[i]);let start=time;time+=proc[original];let late=if time>dead[original]:time-dead[original] else:0
        ml_put(out,mut p,Int32(original));ml_put(out,mut p,Int32(start));ml_put(out,mut p,Int32(late))
    return Int64(bytes)
