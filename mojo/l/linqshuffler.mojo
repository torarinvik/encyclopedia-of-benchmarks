from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn linq_next(mut a:InlineArray[Int64,56],mut i:Int,mut ip:Int)->Int64:
    i+=1
    if i>=56:i=1
    ip+=1
    if ip>=56:ip=1
    var sample=a[i]-a[ip]
    if sample==2147483647:sample-=1
    if sample<0:sample+=2147483647
    a[i]=sample
    return sample
fn linq_put(out:UnsafePointer[UInt8,MutAnyOrigin],slot:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):out[slot*8+j]=UInt8((b>>(8*j))&255)
@export("linqshuffler")
fn linqshuffler(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>67:return -1
    let nv=v[0];let seed=v[1]
    if nv<0 or nv>64 or seed < -2147483648 or seed>2147483647 or n!=c_size_t(nv+2):return -1
    var values=InlineArray[Int64,64](fill=0);var keys=InlineArray[Int64,64](fill=0)
    for i in range(Int(nv)):
        if v[i+2] < -2147483648 or v[i+2]>2147483647:return -1
        values[i]=v[i+2]
    let sub=if seed == -2147483648:2147483647 elif seed<0:-seed else:seed
    var a=InlineArray[Int64,56](fill=0);var mj:Int64=161803398-sub;a[55]=mj;var mk:Int64=1
    for i in range(1,55):
        let ii=(21*i)%55;a[ii]=mk;mk=mj-mk
        if mk<0:mk+=2147483647
        mj=a[ii]
    for _ in range(4):
        for i in range(1,56):
            let oi=1+(i+30)%55;a[i]-=a[oi]
            if a[i]<0:a[i]+=2147483647
    var ix=0;var ip=21
    for i in range(Int(nv)):keys[i]=linq_next(a,ix,ip)
    for i in range(1,Int(nv)):
        let key=keys[i];let val=values[i];var j=i
        while j>0 and keys[j-1]>key:keys[j]=keys[j-1];values[j]=values[j-1];j-=1
        keys[j]=key;values[j]=val
    let bytes=8*(Int(nv)+1)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    linq_put(out,0,nv)
    for i in range(Int(nv)):linq_put(out,i+1,values[i])
    return Int64(bytes)
