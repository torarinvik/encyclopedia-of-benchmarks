from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
@export("golomb_sequence_validator")
fn golomb_sequence_validator(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1024 or v[0]<1 or v[0]>1024 or n!=c_size_t(v[0]):return -1
    let count=Int(v[0]);for i in range(1,count):if v[i]< -2147483648 or v[i]>2147483647:return -1
    var dp=InlineArray[Int64,1024](fill=0);dp[0]=1
    for i in range(1,count):
        let previous=Int(dp[i-1]);let nested=Int(dp[previous]);let source=i-nested;dp[i]=1+dp[source]
    for i in range(1,count):if v[i]!=dp[i]:return 0
    return 1
