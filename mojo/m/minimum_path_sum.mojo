from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_path_sum")
fn minimum_path_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>66 or v[0]<1 or v[0]>8 or v[1]<1 or v[1]>8 or Int(n)!=2+Int(v[0]*v[1]):return -9223372036854775808
    let rows=Int(v[0]);let cols=Int(v[1]);var dp=InlineArray[Int64,8](fill=0)
    for r in range(rows):
        for c in range(cols):
            let x=v[2+r*cols+c]
            if x<0 or x>1000:return -9223372036854775808
            if r==0 and c==0:dp[c]=x
            elif r==0:dp[c]=dp[c-1]+x
            elif c==0:dp[c]+=x
            else:dp[c]=(if dp[c-1]<dp[c]:dp[c-1] else:dp[c])+x
    return dp[cols-1]
