from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_cost_path")
fn minimum_cost_path(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>257 or v[0]<1 or v[0]>16 or v[1]<1 or v[1]>16 or Int(n)!=2+Int(v[0]*v[1]):return -9223372036854775808
    let r=Int(v[0]);let c=Int(v[1]);var dp=InlineArray[Int64,256](fill=0)
    for i in range(r):
        for j in range(c):
            let x=v[2+i*c+j]
            if x < -2147483648 or x>2147483647:return -9223372036854775808
            if i==0 and j==0:dp[0]=x
            elif i==0:dp[j]=dp[j-1]+x
            elif j==0:dp[j]+=x
            else:dp[j]=(if dp[j]<dp[j-1]:dp[j] else:dp[j-1])+x
    return dp[c-1]
