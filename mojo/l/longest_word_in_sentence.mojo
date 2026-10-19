from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn ascii_ws(x:Int64)->Bool:return x==32 or (x>=9 and x<=13)
@export("longest_word_in_sentence")
fn longest_word_in_sentence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>1024 or n!=c_size_t(v[0]+1):return -1
    let len=Int(v[0])
    for i in range(len):
        let x=v[i+1]
        if not ascii_ws(x) and (x<33 or x>126):return -1
    var bests=0;var best=0;var i=0
    while i<len:
        if ascii_ws(v[i+1]):i+=1;continue
        let s=i
        while i<len and not ascii_ws(v[i+1]):i+=1
        if i-s>best:bests=s;best=i-s
    if best>Int(cap) or (best>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for j in range(best):out[j]=UInt8(v[1+bests+j])
    return Int64(best)
