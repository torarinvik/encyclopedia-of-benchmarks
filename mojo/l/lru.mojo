from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer

comptime MAXOPS=32
comptime MAXCAP=16
comptime MAXFIELDS=114

fn lru_store(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):out[at+b]=UInt8((bits>>(b*8))&255)

@export("lru")
fn lru(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>99:return -1
    let capacity=v[0];let ops=v[1]
    if capacity<2 or capacity>MAXCAP or ops<0 or ops>MAXOPS or n!=c_size_t(2+3*ops):return -1
    var seen=InlineArray[Int64,MAXOPS](fill=0);var seen_n=0
    for i in range(Int(ops)):
        let pos=2+3*i;let opcode=v[pos];let key=v[pos+1];let value=v[pos+2]
        if key < -1000000 or key>1000000:return -1
        if opcode==0:
            if value < -1000000 or value>1000000:return -1
            for j in range(seen_n):
                if seen[j]==key:return -1
            seen[seen_n]=key;seen_n+=1
        elif opcode==1:
            if value!=0:return -1
        else:return -1
    var keys=InlineArray[Int64,MAXCAP](fill=0);var values=InlineArray[Int64,MAXCAP](fill=0);var order=InlineArray[Int64,MAXCAP](fill=0);var count=0
    var result=InlineArray[Int64,MAXFIELDS](fill=0);var fields=0
    for i in range(Int(ops)):
        let pos=2+3*i;let opcode=v[pos];let key=v[pos+1];let value=v[pos+2]
        if opcode==0:
            var slot=0
            if count==Int(capacity):
                slot=Int(order[0])
                for j in range(count-1):order[j]=order[j+1]
                count-=1
            else:slot=count
            keys[slot]=key;values[slot]=value;order[count]=Int64(slot);count+=1
            result[fields]=0;result[fields+1]=0;fields+=2
        else:
            var at=0
            while at<count and keys[Int(order[at])]!=key:at+=1
            if at==count:return -1
            let slot=Int(order[at]);let cached=values[slot]
            for j in range(at,count-1):order[j]=order[j+1]
            order[count-1]=Int64(slot)
            result[fields]=1;result[fields+1]=1;result[fields+2]=cached;fields+=3
    result[fields]=2;result[fields+1]=Int64(count);fields+=2
    for j in range(count):
        let slot=Int(order[j]);result[fields]=keys[slot];result[fields+1]=values[slot];fields+=2
    let bytes=fields*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(fields):lru_store(out,i*8,result[i])
    return Int64(bytes)
