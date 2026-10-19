from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("number_of_subarrays_with_odd_sum")
fn number_of_subarrays_with_odd_sum(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>100000:return -1
    var even:Int64=1;var odd:Int64=0;var parity=0;var answer:Int64=0
    for i in range(Int(n)):
        if a==UnsafePointer[Int64,ImmutAnyOrigin]():return -1
        if a[i]< -2147483648 or a[i]>2147483647:return -1
        parity=parity^(Int(a[i])&1)
        if parity==0:answer+=odd;even+=1
        else:answer+=even;odd+=1
        answer=answer%1000000007
    return answer
