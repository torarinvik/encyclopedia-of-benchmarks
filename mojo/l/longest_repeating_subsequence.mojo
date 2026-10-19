from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_repeating_subsequence")
fn longest_repeating_subsequence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>256 or v[0]<0 or v[0]>255 or n!=c_size_t(v[0]+1):return -1
    let size=Int(v[0])
    for i in range(size):
        if v[1+i]<0 or v[1+i]>127:return -1
    var dp=InlineArray[Int64,256](fill=0)
    for i in range(1,size+1):
        var diag:Int64=0
        for j in range(1,size+1):
            let above=dp[j]
            if v[i]==v[j] and i!=j:dp[j]=diag+1
            elif dp[j-1]>dp[j]:dp[j]=dp[j-1]
            diag=above
    return dp[size]
