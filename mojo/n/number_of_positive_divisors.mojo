from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("number_of_positive_divisors")
fn number_of_positive_divisors(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or a[0]< -1000000000 or a[0]>1000000000:return -1
    if a[0]==0:return 1
    var value=a[0];if value<0:value= -value
    var count:Int64=1;var factor:Int64=2
    while factor*factor<=value:
        if value%factor==0:
            var exponent:Int64=0
            while value%factor==0:value=value/factor;exponent+=1
            count*=exponent+1
        factor+=1
    if value>1:count*=2
    return count
