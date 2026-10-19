from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer

fn put_i64(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let bits=UInt64(x)
    for b in range(8):out[at+b]=UInt8((bits>>(8*b))&255)
@export("least_recently_used")
fn least_recently_used(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>67:return -1
    let capacity=v[0];let refs=v[1]
    if capacity<1 or capacity>16 or refs<0 or refs>64 or n!=c_size_t(2+refs):return -1
    for i in range(Int(refs)):
        if v[2+i]<-2147483648 or v[2+i]>2147483647:return -1
    var keys=InlineArray[Int64,16](fill=0);var count=0
    for i in range(Int(refs)):
        let key=v[2+i];var found=count
        for j in range(count):
            if keys[j]==key:found=j;break
        if found<count:
            for j in range(found,count-1):keys[j]=keys[j+1]
            count-=1
        elif count==Int(capacity):count-=1
        var j=count
        while j>0:keys[j]=keys[j-1];j-=1
        keys[0]=key;count+=1
    let elems=count+1;let required=elems*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(required):return -2
    put_i64(out,0,Int64(count))
    for i in range(count):put_i64(out,8*(i+1),keys[i])
    return Int64(elems)
