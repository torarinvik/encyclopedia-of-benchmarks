from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sw_select(v:UnsafePointer[Int64,MutAnyOrigin],n:Int,k:Int)->Int64:
    var low=0;var high=n-1
    while low<high:
        var left=low;var right=high;let pivot=v[(left+right+1)/2]
        while left<=right:
            while left<=right and v[left]<pivot:left+=1
            while left<=right and v[right]>pivot:right-=1
            if left<=right:let t=v[left];v[left]=v[right];v[right]=t;left+=1;right-=1
        if k<=right:high=right
        elif k>=left:low=left
        else:break
    return v[k]
@export("simplified_wiggle_sort")
fn simplified_wiggle_sort(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var v=InlineArray[Int64,4096]();var out=InlineArray[Int64,4096]()
    for i in range(Int(n)):if a[i]< -2147483648 or a[i]>2147483647:return -1;v[i]=a[i]
    let bytes=Int(n)*4;if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    if n==0:return 0
    let med=sw_select(v.unsafe_ptr(),Int(n),Int(n)/2);var small=0;var great=(Int(n)-1-(Int(n)%2))
    for i in range(Int(n)):
        if v[i]>med:out[great]=v[i];great-=2
        elif small<Int(n):out[small]=v[i];small+=2
        else:out[great]=v[i];great-=2
    for i in range(Int(n)):let z=bitcast[UInt32](Int32(out[i]));for b in range(4):o[4*i+b]=UInt8((z>>UInt(8*b))&255)
    return n
