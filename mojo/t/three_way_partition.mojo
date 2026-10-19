from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("three_way_partition")
fn three_way_partition(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258:return -1
    let count=a[0];let pivot=a[1]
    if count<0 or count>256 or n!=c_size_t(count+2) or pivot< -2147483648 or pivot>2147483647:return -1
    var v=InlineArray[Int64,256]()
    for i in range(Int(count)):
        if a[i+2]< -2147483648 or a[i+2]>2147483647:return -1
        v[i]=a[i+2]
    var low=0;var mid=0;var high=Int(count)
    while mid<high:
        if v[mid]<pivot:let t=v[low];v[low]=v[mid];v[mid]=t;low+=1;mid+=1
        elif v[mid]>pivot:high-=1;let t=v[mid];v[mid]=v[high];v[high]=t
        else:mid+=1
    let bytes=(Int(count)+2)*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(count)):
        let bits=UInt32(Int32(v[i]))
        for b in range(4):o[i*4+b]=UInt8((bits>>(8*b))&255)
    for j in range(2):
        let z=UInt32(Int32(low if j==0 else high));let k=Int(count)+j
        for b in range(4):o[k*4+b]=UInt8((z>>(8*b))&255)
    return Int64(count+2)
