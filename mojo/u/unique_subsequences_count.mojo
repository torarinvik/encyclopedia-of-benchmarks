from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("unique_subsequences_count")
fn unique_subsequences_count(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>31:return -1
    let count=v[0]
    if count<0 or count>30 or n!=c_size_t(count+1):return -1
    for i in range(Int(count)):if v[i+1]<0 or v[i+1]>127:return -1
    var dp=InlineArray[Int64,31](fill=0)
    for endstep in range(Int(count)):
        let end=Int(count)-1-endstep
        var seen=InlineArray[UInt8,128](fill=0)
        for at in range(end,Int(count)):
            let ch=Int(v[at+1])
            if seen[ch]!=0:continue
            seen[ch]=1
            dp[end]+=1
            if at+1<Int(count):dp[end]+=dp[at+1]
    return dp[0]
