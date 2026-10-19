from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("maximum_frequency_after_increments")
fn maximum_frequency_after_increments(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257 or v[0]<0 or v[0]>1000000:return -1
    let count=Int(n)-1;var a=InlineArray[Int64,256](fill=0)
    for i in range(count):
        let x=v[i+1];if x<1 or x>10000:return -1
        var j=i;while j>0 and a[j-1]>x:a[j]=a[j-1];j-=1;a[j]=x
    var left=0;var sum:Int64=0;var best=0
    for right in range(count):
        sum+=a[right]
        while a[right]*Int64(right-left+1)-sum>v[0]:sum-=a[left];left+=1
        if right-left+1>best:best=right-left+1
    return Int64(best)
