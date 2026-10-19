from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn trimb(x:Int64)->Bool:return x>=0 and x<=32
fn splb(x:Int64)->Bool:return x==32 or (x>=9 and x<=13)
@export("reverse_words_in_string")
fn reverse_words_in_string(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>258 or v[0]<0 or v[0]>256 or Int(n)!=Int(v[0])+1:return -1
    let size=Int(v[0]);for i in range(size):if v[i+1]<0 or v[i+1]>127:return -1
    var start=0;var end=size
    while start<end and trimb(v[start+1]):start+=1
    while end>start and trimb(v[end]):end-=1
    var olen=0;var words=0;var pos=start
    while pos<end:
        while pos<end and splb(v[pos+1]):pos+=1
        if pos<end:
            let s=pos
            while pos<end and not splb(v[pos+1]):pos+=1
            olen+=pos-s;if words>0:olen+=1;words+=1
    if cap<c_size_t(olen) or (olen>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var w=0;var emitted=0;pos=end
    while pos>start:
        while pos>start and splb(v[pos]):pos-=1
        if pos<=start:break
        let e=pos;while pos>start and not splb(v[pos]):pos-=1
        let s=pos
        if emitted>0:o[w]=32;w+=1
        for i in range(s,e):o[w]=UInt8(v[i+1]);w+=1
        emitted+=1
    return Int64(w)
