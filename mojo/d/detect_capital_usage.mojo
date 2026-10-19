from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("detect_capital_usage")
fn detect_capital_usage(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>1024 or (length!=0 and input==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var upper=0
    for i in range(Int(length)):
        let c=input[i]
        if not ((c>=65 and c<=90) or (c>=97 and c<=122)):return -1
        if c>=65 and c<=90:upper+=1
    return 1 if upper==0 or upper==Int(length) or (upper==1 and length>0 and input[0]>=65 and input[0]<=90) else 0
