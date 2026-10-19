from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("squares_of_a_sorted_array")
fn squares_of_a_sorted_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>10000 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i]< -10000 or v[i]>10000 or (i>0 and v[i-1]>v[i]):return -1
    let bytes=Int(n)*8
    if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var left=0;var right=Int(n);var dst=Int(n);var stage=InlineArray[Int64,10000](fill=0)
    while dst>0:
        dst-=1;let lv=v[left];let rv=v[right-1];let lm=if lv<0 then -lv else lv;let rm=if rv<0 then -rv else rv
        var x:Int64=0
        if lm>rm:x=lv;left+=1
        else:x=rv;right-=1
        stage[dst]=x*x
    for i in range(Int(n)):let bits=bitcast[UInt64](stage[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(n)
