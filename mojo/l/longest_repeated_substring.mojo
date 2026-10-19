from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("longest_repeated_substring")
fn longest_repeated_substring(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>128 or v[0]<0 or v[0]>127 or n!=c_size_t(v[0]+1):return -1
    let len=Int(v[0])
    for i in range(len):
        if v[i+1]<0 or v[i+1]>127:return -1
    var dp=InlineArray[Int64,16384](fill=0);var best:Int64=0
    for ir in range(len):
        let i=len-1-ir
        var jr=0
        while jr<len-i-1:
            let j=len-1-jr
            if v[i+1]==v[j+1]:dp[i*128+j]=1+dp[(i+1)*128+j+1];best=max(best,dp[i*128+j])
            jr+=1
    return best
