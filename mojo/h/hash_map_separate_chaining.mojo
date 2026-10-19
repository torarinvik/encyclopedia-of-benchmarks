from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn hmsc_byte(h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*1099511628211
@export("hash_map_separate_chaining")
fn hash_map_separate_chaining(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1:return -1
    let ops=a[0];if ops<0 or ops>512 or n!=c_size_t(1+3*ops):return -1
    var heads=InlineArray[Int,16](fill=-1);var keys=InlineArray[Int64,128](fill=0);var vals=InlineArray[Int64,128](fill=0);var next=InlineArray[Int,128](fill=-1);var occupied=InlineArray[Bool,128](fill=false);var size=0
    var h:UInt64=14695981039346656037
    for i in range(Int(ops)):
        let op=a[1+3*i];let key=a[2+3*i];let value=a[3+3*i]
        if op<0 or op>4:return -1
        var result_code:UInt8=0;var get_found=-1
        if op==4:
            if key!=0 or value!=0:return -1
            for b in range(16):heads[b]= -1
            for j in range(128):occupied[j]=false;next[j]= -1
            size=0
        else:
            if key<0 or key>99999:return -1
            let bucket=Int(key%16);var prev=-1;var cur=heads[bucket]
            while cur>=0 and keys[cur]!=key:prev=cur;cur=next[cur]
            if op==0:
                if value< -2147483648 or value>2147483647:return -1
                if cur>=0:vals[cur]=value
                else:
                    if size>=128:return -1
                    var slot=-1
                    for j in range(128):if not occupied[j] and slot<0:slot=j
                    if slot<0:return -1
                    keys[slot]=key;vals[slot]=value;occupied[slot]=true;next[slot]= -1
                    if heads[bucket]<0:heads[bucket]=slot
                    else:
                        var tail=heads[bucket]
                        while next[tail]>=0:tail=next[tail]
                        next[tail]=slot
                    size+=1
            else:
                if value!=0:return -1
                if op==1:
                    if cur>=0:result_code=1;get_found=cur
                elif op==2:
                    if cur>=0:
                        if prev<0:heads[bucket]=next[cur]
                        else:next[prev]=next[cur]
                        occupied[cur]=false;next[cur]= -1;size-=1
                elif op==3:result_code=1 if cur>=0 else 0
        h=hmsc_byte(h,UInt8(op));h=hmsc_byte(h,result_code)
        if op==1 and get_found>=0:
            let v=bitcast[UInt32](Int32(vals[get_found]))
            for b in range(4):h=hmsc_byte(h,UInt8((v>>UInt(8*b))&255))
    return Int64(h&0x7fffffffffffffff)
