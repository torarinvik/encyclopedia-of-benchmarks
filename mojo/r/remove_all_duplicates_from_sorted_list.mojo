from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("remove_all_duplicates_from_sorted_list")
fn remove_all_duplicates_from_sorted_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>1024 or (n!=0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i] < -2147483648 or v[i]>2147483647 or (i>0 and v[i-1]>v[i]):return -1
    var staged=InlineArray[Int64,1024](fill=0);var count=0;var i=0
    while i<Int(n):
        var end=i+1
        while end<Int(n) and v[end]==v[i]:end+=1
        if end==i+1:staged[count]=v[i];count+=1
        i=end
    let bytes=count*4
    if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(count):
        let b=UInt32(Int32(staged[i]))
        for j in range(4):o[i*4+j]=UInt8((b>>(8*j))&255)
    return Int64(count)
