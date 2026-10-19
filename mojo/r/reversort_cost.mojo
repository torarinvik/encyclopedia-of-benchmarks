from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("reversort_cost")
fn reversort_cost(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var a=InlineArray[Int64,256](fill=0)
    for i in range(Int(n)):if v[i]< -2147483648 or v[i]>2147483647:return -1
    for i in range(Int(n)):a[i]=v[i]
    var cost=0
    for i in range(Int(n)-1):
        var m=i
        for j in range(i+1,Int(n)):if a[j]<a[m]:m=j
        var l=i;var r=m
        while l<r:let t=a[l];a[l]=a[r];a[r]=t;l+=1;r-=1
        cost+=m-i+1
    return Int64(cost)
