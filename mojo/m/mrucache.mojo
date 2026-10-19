from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn mr_byte(h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*1099511628211
@export("mrucache")
fn mrucache(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>387:return -1
    let cap=Int(v[0]);let q=Int(v[1]);if cap<1 or cap>16 or q<0 or q>128 or Int(n)!=2+3*q:return -1
    var keys=InlineArray[Int32,16](fill=0);var vals=InlineArray[Int32,16](fill=0);var count=0;var res=InlineArray[Int32,128](fill=0);var nr=0
    for step in range(q):
        let op=v[2+3*step];let key=v[3+3*step];let value=v[4+3*step]
        if op<0 or op>1 or key < -2147483648 or key>2147483647 or value < -2147483648 or value>2147483647:return -1
        var pos=0;while pos<count and keys[pos]!=Int32(key):pos+=1
        if op==0:
            if value<0 or value>1000000:return -1
            if pos<count:
                for j in range(pos,count-1):keys[j]=keys[j+1];vals[j]=vals[j+1]
                keys[count-1]=Int32(key);vals[count-1]=Int32(value)
            else:
                if count==cap:count-=1
                keys[count]=Int32(key);vals[count]=Int32(value);count+=1
        elif pos==count:res[nr]=-1;nr+=1
        else:
            let answer=vals[pos]
            for j in range(pos,count-1):keys[j]=keys[j+1];vals[j]=vals[j+1]
            keys[count-1]=Int32(key);vals[count-1]=answer;res[nr]=answer;nr+=1
    var h:UInt64=14695981039346656037;h=mr_byte(h,UInt8(nr&255));h=mr_byte(h,UInt8((nr>>8)&255))
    for i in range(nr):let u=UInt32(res[i]);for b in range(4):h=mr_byte(h,UInt8((u>>(8*b))&255))
    return Int64(h&0x7fffffffffffffff)
