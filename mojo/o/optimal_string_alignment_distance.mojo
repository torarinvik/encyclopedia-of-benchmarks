from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("optimal_string_alignment_distance")
fn optimal_string_alignment_distance(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1
    let a=Int(v[0]);let b=Int(v[1])
    if a<0 or a>32 or b<0 or b>32 or n!=c_size_t(2+a+b):return -1
    for i in range(a):if v[2+i]<0 or v[2+i]>127:return -1
    for j in range(b):if v[2+a+j]<0 or v[2+a+j]>127:return -1
    var dp=InlineArray[Int64,1156](fill=0)
    for i in range(a+1):dp[i*34]=Int64(i)
    for j in range(b+1):dp[j]=Int64(j)
    for i in range(1,a+1):
        for j in range(1,b+1):
            let cost=if v[1+i]==v[1+a+j]:0 else:1
            var best=dp[(i-1)*34+j]+1
            best=min(best,dp[i*34+j-1]+1);best=min(best,dp[(i-1)*34+j-1]+cost)
            if i>1 and j>1 and v[i]==v[2+a+j-1] and v[i-1]==v[2+a+j]:best=min(best,dp[(i-2)*34+j-2]+cost)
            dp[i*34+j]=best
    return dp[a*34+b]
