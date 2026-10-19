from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("missing_number_in_range")
fn missing_number_in_range(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1024:return -2147483649
    var low=v[0];var high=v[0]
    for i in range(Int(n)):
        let x=v[i]
        if x < -2147483648 or x>2147483647:return -2147483649
        if x<low:low=x
        if x>high:high=x
    if high-low!=Int64(n):return -2147483649
    var seen=InlineArray[Int64,1025](fill=0);var actual:UInt64=0
    for i in range(Int(n)):
        let x=v[i];let slot=Int(x-low)
        if seen[slot]!=0:return -2147483649
        seen[slot]=1
        let u=UInt64(if x<0:x+4294967296 else:x);actual^=u
    var expected:UInt64=0;var x=low
    while x<=high:
        expected^=UInt64(if x<0:x+4294967296 else:x);x+=1
    let res=expected^actual
    return Int64(res) if res<=2147483647 else Int64(res)-4294967296
