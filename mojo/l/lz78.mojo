from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn lz78_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(j*8))&255)
@export("lz78_compress")
fn lz78_compress(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>66 or v[0]<0 or v[0]>64 or n!=c_size_t(v[0]+1):return -1
    let size=Int(v[0])
    for i in range(size):if v[i+1]<32 or v[i+1]>126:return -1
    var children=InlineArray[Int64,6175](fill=0);var pref=InlineArray[Int64,64](fill=0);var chars=InlineArray[Int64,64](fill=0);var node_count=1;var current=0;var last=0;var tokens=0
    for i in range(size):
        let edge=Int(v[i+1]-32);let child=Int(children[current*95+edge])
        if child!=0:current=child;last=child
        else:
            pref[tokens]=Int64(last);chars[tokens]=v[i+1];tokens+=1
            children[current*95+edge]=Int64(node_count);node_count+=1;current=0;last=0
    if current!=0:pref[tokens]=Int64(last);chars[tokens]=0;tokens+=1
    let bytes=tokens*16
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(tokens):lz78_put(o,i*16,pref[i]);lz78_put(o,i*16+8,chars[i])
    return Int64(bytes)
