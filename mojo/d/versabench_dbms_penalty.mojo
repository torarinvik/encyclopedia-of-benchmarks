from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("versabench_dbms_penalty")
fn versabench_dbms_penalty(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 16: return -1
    for box_index in range(2):
        let base = 8 * box_index
        for d in range(4):
            let lower = input[base + d]
            let upper = input[base + 4 + d]
            if lower < -8 or lower > 8 or upper < -8 or upper > 8 or lower >= upper: return -1
    var joined: Int64 = 1
    var original: Int64 = 1
    for d in range(4):
        var lower = input[d]
        var upper = input[4 + d]
        if input[8 + d] < lower: lower = input[8 + d]
        if input[12 + d] > upper: upper = input[12 + d]
        joined *= upper - lower
        original *= input[4 + d] - input[d]
    return joined - original
