from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("needleman_wunsch")
fn needleman_wunsch(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>261:return -9223372036854775808
    let m=a[0];let l=a[1];let ms=a[2];let mm=a[3];let gap=a[4]
    if m<0 or m>128 or l<0 or l>128 or ms<0 or ms>10 or mm< -10 or mm>0 or gap< -10 or gap>0 or n!=c_size_t(5+m+l):return -9223372036854775808
    for i in range(5,Int(n)):if a[i]<65 or a[i]>90:return -9223372036854775808
    var dp=InlineArray[Int64,129]();for j in range(Int(l)+1):dp[j]=Int64(j)*gap
    for i in range(1,Int(m)+1):
        var diag=dp[0];dp[0]=Int64(i)*gap
        for j in range(1,Int(l)+1):
            let old=dp[j];let score=ms if a[5+i-1]==a[5+Int(m)+j-1] else mm
            dp[j]=max(diag+score,max(old+gap,dp[j-1]+gap));diag=old
    return dp[Int(l)]
