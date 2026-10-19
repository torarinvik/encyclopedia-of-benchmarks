from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn list_put64(out:UnsafePointer[UInt8,MutAnyOrigin],slot:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):out[slot*8+j]=UInt8((b>>(8*j))&255)
@export("list_array")
fn list_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capout:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130:return -1
    let capacity=v[0];let ops=v[1]
    if capacity<1 or capacity>16 or ops<1 or ops>64 or n!=c_size_t(2+2*ops):return -1
    var opcodes=InlineArray[Int64,64](fill=0);var args=InlineArray[Int64,64](fill=0);var sorted=False
    for i in range(Int(ops)):
        let op=v[2+2*i];let arg=v[3+2*i]
        if op==0:
            if sorted or arg<0:return -1
        elif op==1:
            if sorted or arg!=0:return -1
            sorted=True
        elif op==2 or op==3:
            if not sorted or arg<0:return -1
        else:return -1
        opcodes[i]=op;args[i]=arg
    if not sorted:return -1
    var items=InlineArray[UInt64,16](fill=0);var results=InlineArray[Int64,64](fill=0);var count=0;var rc=0
    for i in range(Int(ops)):
        let op=opcodes[i];let arg=args[i]
        if op==0:
            if count==Int(capacity):return -1
            items[count]=UInt64(arg);count+=1
        elif op==1:
            for a in range(count):
                var mi=a
                for b in range(a+1,count):
                    if items[b]<items[mi]:mi=b
                let z=items[mi];items[mi]=items[a];items[a]=z
        else:
            if count==0 or UInt64(arg)<items[0] or (op==3 and count>=Int(capacity)):return -1
            var lo=0;var hi=count-1;var pos:Int64=-1
            while lo<=hi:
                let mid=(lo+hi)/2
                if items[mid]==UInt64(arg):pos=Int64(mid);break
                elif UInt64(arg)<items[mid]:hi=mid-1
                else:lo=mid+1
            results[rc]=pos;rc+=1
            if op==3 and pos>=0:
                for j in range(Int(pos),count):items[j]=items[j+1]
                count-=1
    var words=InlineArray[Int64,65](fill=0);var wc=0;words[wc]=Int64(rc);wc+=1
    for i in range(rc):words[wc]=results[i];wc+=1
    words[wc]=Int64(count);wc+=1
    for i in range(count):words[wc]=Int64(items[i]);wc+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capout<c_size_t(wc*8):return -2
    for i in range(wc):list_put64(out,i,words[i])
    return Int64(wc*8)
