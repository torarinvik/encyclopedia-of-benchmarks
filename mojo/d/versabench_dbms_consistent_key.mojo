from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("versabench_dbms_consistent_key")
fn versabench_dbms_consistent_key(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 16: return -1
    for box_index in range(2):
        let base = 8 * box_index
        for d in range(4):
            let lower = input[base + d]
            let upper = input[base + 4 + d]
            if lower < -8 or lower > 8 or upper < -8 or upper > 8 or lower > upper: return -1
    for d in range(4):
        if input[d] > input[12 + d] or input[8 + d] > input[4 + d]: return 0
    return 1
