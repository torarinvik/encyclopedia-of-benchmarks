from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_increasing_subsequence_iterative")
fn longest_increasing_subsequence_iterative(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65 or v[0]<0 or v[0]>64 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0]);var a=InlineArray[Int64,64](fill=0);var dp=InlineArray[Int64,64](fill=0)
    for i in range(count):
        a[i]=v[i+1]
        if a[i] < -1000000 or a[i]>1000000:return -1
        dp[i]=1
    for i in range(count):
        for j in range(i):
            if a[j]<=a[i] and dp[j]+1>dp[i]:dp[i]=dp[j]+1
    var best:Int64=0
    for i in range(count):best=max(best,dp[i])
    return best
