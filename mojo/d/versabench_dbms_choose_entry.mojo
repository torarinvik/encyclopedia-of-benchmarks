from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("versabench_dbms_choose_entry")
fn versabench_dbms_choose_entry(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 74: return -1
    if input[0] < 1 or input[0] > 8: return -1
    let count = Int(input[0])
    if Int(length) != 1 + 8 * count + 8: return -1
    let incoming = 1 + 8 * count
    for box_index in range(count + 1):
        let base = 1 + 8 * box_index
        for d in range(4):
            let lower = input[base + d]
            let upper = input[base + 4 + d]
            if lower < -8 or lower > 8 or upper < -8 or upper > 8 or lower >= upper: return -1
    var best: Int64 = 0
    var best_penalty: Int64 = 65536
    for child in range(count):
        let base = 1 + 8 * child
        var joined: Int64 = 1
        var original: Int64 = 1
        for d in range(4):
            var lower = input[base + d]
            var upper = input[base + 4 + d]
            if input[incoming + d] < lower: lower = input[incoming + d]
            if input[incoming + 4 + d] > upper: upper = input[incoming + 4 + d]
            joined *= upper - lower
            original *= input[base + 4 + d] - input[base + d]
        let penalty = joined - original
        if penalty < best_penalty:
            best = Int64(child)
            best_penalty = penalty
    return best
