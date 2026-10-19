from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("trapped_rainwater")
fn trapped_rainwater(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if a[i]<0 or a[i]>1000000:return -1
    if n<3:return 0
    let count=Int(n);var left=InlineArray[Int64,4096]();var right=InlineArray[Int64,4096]()
    left[0]=a[0]
    for i in range(1,count):left[i]=max(left[i-1],a[i])
    right[count-1]=a[count-1]
    for j in range(1,count):let i=count-j-1;right[i]=max(right[i+1],a[i])
    var water:Int64=0
    for i in range(count):water+=min(left[i],right[i])-a[i]
    return water
