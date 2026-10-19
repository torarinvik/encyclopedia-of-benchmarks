from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn lifo_put(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let bits=UInt64(x)
    for j in range(8):out[at+j]=UInt8((bits>>(8*j))&255)
@export("lifocache")
fn lifocache(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>194:return -1
    let capacity=v[0];let ops=v[1]
    if capacity<1 or capacity>16 or ops<1 or ops>64 or n!=c_size_t(2+3*ops):return -1
    for i in range(Int(ops)):
        let p=2+3*i;let op=v[p];let key=v[p+1];let value=v[p+2]
        if op<0 or op>6:return -1
        if op<=2:
            if key < -2147483648 or key>2147483647:return -1
            if op==0:
                if value < -2147483648 or value>2147483647:return -1
            elif value!=0:return -1
        elif key!=0 or value!=0:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(Int(ops)*16):return -2
    var keys=InlineArray[Int64,16](fill=0);var vals=InlineArray[Int64,16](fill=0);var size=0;var hits:Int64=0;var misses:Int64=0
    var staged=InlineArray[Int64,128](fill=0)
    for i in range(Int(ops)):
        let p=2+3*i;let op=v[p];let key=v[p+1];let val=v[p+2];var first:Int64=0;var second:Int64=0
        if op==0:
            var found=size
            for j in range(size):
                if keys[j]==key:found=j;break
            if found<size:
                for j in range(found,size-1):keys[j]=keys[j+1];vals[j]=vals[j+1]
                size-=1
            if size==Int(capacity):size-=1
            keys[size]=key;vals[size]=val;size+=1;first=1
        elif op==1:
            var found=size
            for j in range(size):
                if keys[j]==key:found=j;break
            if found<size:hits+=1;first=1;second=vals[found]
            else:misses+=1
        elif op==2:
            var found=size
            for j in range(size):
                if keys[j]==key:found=j;break
            if found<size:
                first=1;second=vals[found]
                for j in range(found,size-1):keys[j]=keys[j+1];vals[j]=vals[j+1]
                size-=1
        elif op==3:first=Int64(size)
        elif op==4:first=hits
        elif op==5:first=misses
        else:size=0;hits=0;misses=0;first=1
        staged[2*i]=first;staged[2*i+1]=second
    for i in range(2*Int(ops)):lifo_put(out,i*8,staged[i])
    return Int64(2*Int(ops))
