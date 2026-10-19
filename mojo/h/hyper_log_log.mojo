from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hyper_log_log")
fn hyper_log_log(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let count=a[0];if count<1 or count>1024 or n!=c_size_t(count+1):return -1
    var seen=InlineArray[Bool,65536](fill=false);var ranks=InlineArray[Int,65536](fill=0);var k=0
    for i in range(Int(count)):
        let x=a[i+1];if x<1 or x>65535:return -1
        if not seen[Int(x)]:
            seen[Int(x)]=true;k+=1;var y=UInt64(x);var rank=0
            while (y&1)==0:rank+=1;y>>=1
            ranks[Int(x)]=rank
    var z=0.0
    for x in range(1,65536):if seen[x]:z+=1.0/Float64(UInt64(1)<<UInt(ranks[x]))
    let est=0.673*Float64(k)*(Float64(k)/z)
    return Int64(Int(est) if Float64(Int(est))==est else Int(est)+1)
