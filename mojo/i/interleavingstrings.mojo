from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("interleavingstrings")
fn interleavingstrings(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3:return -1
    let m=input[0];let k=input[1];let q=input[2]
    if m<0 or m>32 or k<0 or k>32 or q!=m+k or length!=c_size_t(3+m+k+q):return -1
    for i in range(3,Int(length)):
        if input[i]<0 or input[i]>127:return -1
    let second=3+Int(m);let target=second+Int(k)
    var dp=InlineArray[Bool,1089](fill=False);dp[0]=True
    for i in range(Int(m)+1):
        for j in range(Int(k)+1):
            if i>0 and dp[(i-1)*33+j] and input[3+i-1]==input[target+i+j-1]:dp[i*33+j]=True
            if j>0 and dp[i*33+j-1] and input[second+j-1]==input[target+i+j-1]:dp[i*33+j]=True
    return 1 if dp[Int(m)*33+Int(k)] else 0
