from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("detect_capital_usage_scan")
fn detect_capital_usage_scan(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>1024 or (length!=0 and input==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(length)):
        let c=input[i]
        if not ((c>=65 and c<=90) or (c>=97 and c<=122)):return -1
    for i in range(1,Int(length)):
        let c=input[i]
        if c>=65 and c<=90:
            var all_upper=true
            for j in range(Int(length)):
                if input[j]>=97 and input[j]<=122:all_upper=false;break
            if not all_upper:return 0
    return 1
