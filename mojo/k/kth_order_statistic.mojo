from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kth_number")
fn kth_number(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>65 or a[0]<1 or a[0]>=n:return -1
    let k=Int(a[0]);let count=Int(n)-1;var v=InlineArray[Int64,64]();var seen=InlineArray[Bool,20001]()
    for i in range(count):
        let x=a[i+1];if x< -10000 or x>10000 or seen[Int(x+10000)]:return -1
        seen[Int(x+10000)]=True;v[i]=x
    # Deterministic source-compatible partition selection, using the first active value as pivot.
    var lo=0;var hi=count-1;let target=k-1
    while lo<=hi:
        let pivot=v[lo];var left=lo+1;var right=hi
        while left<=right:
            while left<=right and v[left]<pivot:left+=1
            while left<=right and v[right]>pivot:right-=1
            if left<=right:let t=v[left];v[left]=v[right];v[right]=t;left+=1;right-=1
        let t=v[lo];v[lo]=v[right];v[right]=t
        if right==target:return v[right]
        if right>target:hi=right-1
        else:lo=right+1
    return -1
