from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kthnumber")
fn kthnumber(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>19 or a[0]<1 or a[0]>16 or (a[1]!=1 and a[1]!=2) or a[2]<1 or a[2]>a[0] or n!=c_size_t(3+a[0]):return -1
    let count=Int(a[0]);let target=Int(a[2]-1) if a[1]==1 else count-Int(a[2]);var v=InlineArray[Int64,16]()
    for i in range(count):if a[3+i]< -10000 or a[3+i]>10000:return -1;v[i]=a[3+i]
    var lo=0;var hi=count-1
    while lo<=hi:
        let pivot=v[hi];var st=lo
        for i in range(lo,hi):if v[i]<pivot:let t=v[i];v[i]=v[st];v[st]=t;st+=1
        v[st]=pivot
        if st==target:return v[st]
        if st<target:lo=st+1
        else:hi=st-1
    return -1
