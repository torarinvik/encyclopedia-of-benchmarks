from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn gcf_pair(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:let rem=a%b;a=b;b=rem
    return a
@export("greatest_common_factor")
fn greatest_common_factor(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>257:return -9223372036854775807-1
    let count=Int(v[0]);if count<1 or count>256 or n!=c_size_t(count+1):return -9223372036854775807-1
    var result=v[1];if result<0 or result>9007199254740991:return -9223372036854775807-1
    for i in range(2,Int(n)):
        let x=v[i];if x<0 or x>9007199254740991:return -9223372036854775807-1
        result=gcf_pair(result,x)
    return result
