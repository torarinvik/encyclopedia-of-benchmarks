from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("subset_sum_enumerate")
fn subset_sum_enumerate(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>9:return -1
    let target=v[0]
    if target< -512 or target>512:return -1
    let items=Int(n)-1
    for i in range(items):if v[i+1]< -64 or v[i+1]>64:return -1
    var masks=InlineArray[UInt8,256](fill=0);var count=0
    for mask in range(1<<items):
        var sum:Int64=0
        for i in range(items):if (mask>>i)&1==1:sum+=v[i+1]
        if sum==target:masks[count]=UInt8(mask);count+=1
    if cap<c_size_t(count) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(count):o[i]=masks[i]
    return Int64(count)
