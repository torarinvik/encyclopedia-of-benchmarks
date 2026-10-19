from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("external_merge_sorter")
fn external_merge_sorter(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if length>4096 or (length>0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let n=Int(length);let bytes=n*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    var source=List[Int64](length=n,fill=0);var dest=List[Int64](length=n,fill=0)
    for i in range(n):source[i]=values[i]
    var width=1
    while width<n:
        var start=0
        while start<n:
            let middle=min(start+width,n);let end=min(middle+width,n)
            var left=start;var right=middle;var index=start
            while left<middle and right<end:
                if source[left]<source[right]:dest[index]=source[left];left+=1
                else:dest[index]=source[right];right+=1
                index+=1
            while left<middle:dest[index]=source[left];left+=1;index+=1
            while right<end:dest[index]=source[right];right+=1;index+=1
            start+=2*width
        let temp=source;source=dest;dest=temp
        if width>n//2:break
        width*=2
    for i in range(n):
        let bits=bitcast[UInt64](source[i])
        for b in range(8):output[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
