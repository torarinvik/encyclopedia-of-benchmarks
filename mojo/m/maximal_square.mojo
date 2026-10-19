from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("maximal_square")
fn maximal_square(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>258 or v[0]<1 or v[0]>16 or v[1]<1 or v[1]>16:return -1
    let rows=Int(v[0]);let cols=Int(v[1]);if n!=c_size_t(2+rows*cols):return -1
    for i in range(rows*cols):if v[i+2]!=0 and v[i+2]!=1:return -1
    var dp=InlineArray[Int,16](fill=0);var best=0
    for r in range(rows):
        var diag=0
        for c in range(cols):
            let above=dp[c]
            if v[2+r*cols+c]==1:
                if r==0 or c==0:dp[c]=1
                else:
                    var m=diag;if dp[c]<m:m=dp[c];if dp[c-1]<m:m=dp[c-1];dp[c]=m+1
                if dp[c]>best:best=dp[c]
            else:dp[c]=0
            diag=above
    return Int64(best*best)
