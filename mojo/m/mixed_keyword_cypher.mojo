from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("mixed_keyword_cypher")
fn mixed_keyword_cypher(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>578 or v[0]<1 or v[0]>64:return -1
    let kl=Int(v[0]);let pi=1+kl
    if pi>=Int(n) or v[pi]<0 or v[pi]>512:return -1
    let plen=Int(v[pi]);if Int(n)!=pi+1+plen:return -1
    var seen=InlineArray[Int64,26](fill=0);var letters=InlineArray[Int64,26](fill=0);var count=0
    for i in range(kl):
        let raw=v[1+i]
        if raw<0 or raw>127:return -1
        let ch=if raw>=97 and raw<=122:raw-32 else:raw
        if ch>=65 and ch<=90:
            let ix=Int(ch-65)
            if seen[ix]==0:seen[ix]=1;letters[count]=ch;count+=1
    if count==0:return -1
    for i in range(plen):if v[pi+1+i]<0 or v[pi+1+i]>127:return -1
    var shifted=InlineArray[Int64,26](fill=0);var sc=0
    for i in range(count):shifted[sc]=letters[i];sc+=1
    for i in range(26):if seen[i]==0:shifted[sc]=Int64(65+i);sc+=1
    var mapping=InlineArray[Int64,26](fill=0);var idx=0
    for col in range(count):
        var row=0
        while row<26:
            let si=row+col
            if si>=26:break
            mapping[idx]=shifted[si];idx+=1;row+=count
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(plen):return -2
    for i in range(plen):
        let raw=v[pi+1+i];let ch=if raw>=97 and raw<=122:raw-32 else:raw
        out[i]=UInt8(mapping[Int(ch-65)]) if ch>=65 and ch<=90 else UInt8(ch)
    return Int64(plen)
