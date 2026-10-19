from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_palindromic_subsequence")
fn longest_palindromic_subsequence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>128:return -1
    if n==0:return 0
    var dp=InlineArray[Int64,128](fill=0)
    for sr in range(Int(n)):
        let start=Int(n)-1-sr;dp[start]=1;var diagonal:Int64=0
        for end in range(start+1,Int(n)):
            let prev=dp[end]
            if v[start]==v[end]:dp[end]=diagonal+2
            else:dp[end]=max(dp[end],dp[end-1])
            diagonal=prev
    return dp[Int(n)-1]
