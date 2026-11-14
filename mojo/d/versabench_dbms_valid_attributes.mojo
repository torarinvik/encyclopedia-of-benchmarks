from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("versabench_dbms_valid_attributes")
fn versabench_dbms_valid_attributes(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 104: return -1
    let count = input[0]
    if count < 0 or count > 51 or length != c_size_t(1 + 2 * count): return -1
    for i in range(Int(count)):
        let code = input[1 + 2 * i]
        let payload = input[2 + 2 * i]
        if code < 0 or code > 50: return 0
        if code < 8:
            if payload < 0 or payload > 4294967295: return -1
            let bits = UInt64(payload)
            if ((bits >> 23) & 255) == 255 and (bits & 0x7fffff) == 0: return 0
        else:
            if payload != 0 and payload != 1: return -1
            if payload == 0: return 0
    return 1
