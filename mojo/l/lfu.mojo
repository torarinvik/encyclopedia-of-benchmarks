from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn lfu_move(mut keys:InlineArray[Int64,16],mut vals:InlineArray[Int64,16],index:Int):
    let k=keys[index];let v=vals[index]
    for i in range(index):
        let j=index-i;keys[j]=keys[j-1];vals[j]=vals[j-1]
    keys[0]=k;vals[0]=v
fn lfu_put(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let bits=UInt64(x)
    for i in range(8):out[at+i]=UInt8((bits>>(8*i))&255)
@export("lfu")
fn lfu(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>98:return -1
    if v[0]<2 or v[0]>16 or v[1]<0 or v[1]>32:return -1
    let capacity=Int(v[0]);let operations=Int(v[1]);var keys=InlineArray[Int64,16](fill=0);var vals=InlineArray[Int64,16](fill=0);var size=0;var words=InlineArray[Int64,96](fill=0);var wc=0;var pos=2
    for _ in range(operations):
        if pos>=Int(n):return -1
        let op=v[pos];pos+=1
        if op==0:
            if pos+1>=Int(n):return -1
            let key=v[pos];let value=v[pos+1];pos+=2
            if key < -2147483648 or key>2147483647 or value < -2147483648 or value>2147483647:return -1
            var j=0
            while j<size and keys[j]!=key:j+=1
            if j<size:lfu_move(keys,vals,j)
            else:
                if size==capacity:size-=1
                var k=size
                while k>0:keys[k]=keys[k-1];vals[k]=vals[k-1];k-=1
                keys[0]=key;vals[0]=value;size+=1
            words[wc]=0;wc+=1
        elif op==1:
            if pos>=Int(n):return -1
            let key=v[pos];pos+=1
            if key < -2147483648 or key>2147483647:return -1
            var j=0
            while j<size and keys[j]!=key:j+=1
            words[wc]=1;wc+=1
            if j==size:words[wc]=1;wc+=1;words[wc]=0;wc+=1
            else:
                let value=vals[j];lfu_move(keys,vals,j);words[wc]=0;wc+=1;words[wc]=value;wc+=1
        else:return -1
    if pos!=Int(n) or wc>96:return -1
    let bytes=wc*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(wc):lfu_put(out,i*8,words[i])
    return Int64(bytes)
