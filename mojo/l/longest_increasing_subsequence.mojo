from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_increasing_subsequence")
fn longest_increasing_subsequence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>512 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var dp=InlineArray[Int64,512](fill=0);var best:Int64=0
    for i in range(Int(n)):
        dp[i]=1
        for j in range(i):
            if v[i]>v[j] and dp[i]<dp[j]+1:dp[i]=dp[j]+1
        best=max(best,dp[i])
    return best
