from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("maximum_sum_of_distinct_subarrays_with_length_k")
fn maximum_sum_of_distinct_subarrays_with_length_k(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>8194:return -9223372036854775808
    let count=v[0];let k=v[1]
    if count<1 or count>8192 or k<1 or k>count or n!=c_size_t(count+2):return -9223372036854775808
    var keys=InlineArray[Int32,16384](fill=0);var last=InlineArray[Int32,16384](fill=0);var sum:Int64=0;var best:Int64=0;var distinct_start=0
    for i in range(Int(count)):
        let raw=v[i+2];if raw< -2147483648 or raw>2147483647:return -9223372036854775808
        let value=Int32(raw)
        if i<Int(k):sum+=raw else:sum-=v[i-Int(k)+2];sum+=raw
        var slot=Int((raw+2147483648)%16384)
        while last[slot]!=0 and keys[slot]!=value:slot=(slot+1)&16383
        if last[slot]!=0:
            let prev=Int(last[slot]-1);if prev>=distinct_start:distinct_start=prev+1
        else:keys[slot]=value
        last[slot]=Int32(i+1)
        if i+1>=Int(k):
            let start=i+1-Int(k)
            if start>=distinct_start and sum>best:best=sum
    return best
