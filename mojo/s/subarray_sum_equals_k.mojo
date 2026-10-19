from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Int64= -9223372036854775808
fn prefix_slot(x:Int64)->Int:
    let mag=if x<0 then -x else x
    return Int(mag%2048)
@export("subarray_sum_equals_k")
fn subarray_sum_equals_k(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>514:return BAD
    let cv=v[0];let target=v[1]
    if cv<0 or cv>512 or target< -2147483648 or target>2147483647 or n!=c_size_t(cv+2):return BAD
    let count=Int(cv)
    for i in range(count):if v[2+i]< -2147483648 or v[2+i]>2147483647:return BAD
    var keys=InlineArray[Int64,2048](fill=0);var freq=InlineArray[Int64,2048](fill=0);freq[0]=1;var prefix:Int64=0;var result:Int64=0
    for i in range(count):
        prefix+=v[2+i];let required=prefix-target;var slot=prefix_slot(required)
        while freq[slot]!=0 and keys[slot]!=required:slot=(slot+1)%2048
        result+=freq[slot];slot=prefix_slot(prefix)
        while freq[slot]!=0 and keys[slot]!=prefix:slot=(slot+1)%2048
        if freq[slot]==0:keys[slot]=prefix
        freq[slot]+=1
    return result
