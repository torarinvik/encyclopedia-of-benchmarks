from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("second_min_max")
fn second_min_max(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>258:return -9223372036854775808
    let op=a[0];let count=a[1];if (op!=0 and op!=1) or count<2 or count>256 or n!=c_size_t(count+2):return -9223372036854775808
    let init=2147483647 if op==0 else -2147483648;var best=init;var second=init
    for i in range(Int(count)):
        let v=a[i+2];if v< -2147483648 or v>2147483647:return -9223372036854775808
        let better=v<best if op==0 else v>best
        if better:second=best;best=v
        else:
            let imp=v<second if op==0 else v>second
            if imp and v!=best:second=v
    return -9223372036854775808 if second==init else second
