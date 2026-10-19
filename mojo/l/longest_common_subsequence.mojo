from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_common_subsequence")
fn longest_common_subsequence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>512:return -1
    let a=v[0];let b=v[1]
    if a<0 or a>255 or b<0 or b>255 or n!=c_size_t(2+a+b):return -1
    for i in range(Int(a+b)):
        if v[2+i]<0 or v[2+i]>127:return -1
    var dp=InlineArray[Int64,256](fill=0)
    for i in range(Int(a)):
        var diag:Int64=0
        for j in range(1,Int(b)+1):
            let above=dp[j]
            if v[2+i]==v[2+Int(a)+j-1]:dp[j]=diag+1
            elif dp[j-1]>dp[j]:dp[j]=dp[j-1]
            diag=above
    return dp[Int(b)]
