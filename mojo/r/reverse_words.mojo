from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("reverse_words")
fn reverse_words(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>256 or Int(n)!=Int(v[0])+1:return -1
    let size=Int(v[0])
    for i in range(size):let x=v[i+1];if (x!=32 and (x<33 or x>126)) or (x==32 and (i==0 or i+1==size or v[i]!=32)):return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(size+1):return -2
    var w=0;var end=size
    while end>0:
        var start=end
        while start>0 and v[start]!=32:start-=1
        for i in range(start,end):o[w]=UInt8(v[i+1]);w+=1
        if start==0:break
        o[w]=32;w+=1;end=start-1
    o[w]=0;return Int64(w)
