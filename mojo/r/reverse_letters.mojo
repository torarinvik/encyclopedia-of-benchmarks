from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("reverse_letters")
fn reverse_letters(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>256 or Int(n)!=Int(v[0])+1:return -1
    let size=Int(v[0])
    for i in range(size):
        let x=v[i+1]
        if x==32:
            if i==0 or i+1==size or v[i]!=32:return -1
        elif x<33 or x>126:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(size+1):return -2
    var start=0
    while start<size:
        var end=start
        while end<size and v[end+1]!=32:end+=1
        for j in range(end-start+1):o[start+j]=UInt8(v[end-j+1])
        if end<size:o[end]=32
        start=end+1
    o[size]=0
    return Int64(size)
