from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_common_substring")
fn longest_common_substring(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>514 or v[0]<0 or v[0]>256:return -1
    let a=Int(v[0]);if a+2>Int(n) or v[a+1]<0 or v[a+1]>256:return -1
    let b=Int(v[a+1]);if Int(n)!=a+b+2:return -1
    for i in range(a):
        if v[i+1]<32 or v[i+1]>126:return -1
    for i in range(b):
        if v[a+2+i]<32 or v[a+2+i]>126:return -1
    var dp=InlineArray[Int64,257](fill=0);var best:Int64=0
    for i in range(1,a+1):
        var j=b
        while j>0:
            if v[i]==v[a+1+j]:dp[j]=dp[j-1]+1;best=max(best,dp[j])
            else:dp[j]=0
            j-=1
    return best
