from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("versabench_dbms_contract_root")
fn versabench_dbms_contract_root(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 12: return -1
    if input[0] < 1 or input[0] > 5: return -1
    let count = Int(input[0])
    if Int(length) != 1 + 2 * count: return -1
    for i in range(count):
        let level = input[1 + 2 * i]
        let entries = input[2 + 2 * i]
        if level < 0 or level > 4 or entries < 0 or entries > 4: return -1
        if i + 1 < count:
            if level == 0 or entries != 1 or input[1 + 2 * (i + 1)] != level - 1: return -1
    let last_level = input[1 + 2 * (count - 1)]
    let last_entries = input[2 + 2 * (count - 1)]
    if last_level > 0 and last_entries == 1: return -1
    if last_level > 0 and last_entries == 0 and count != 1: return -1
    var root = 0
    while input[1 + 2 * root] > 0 and input[2 + 2 * root] == 1:
        root += 1
    var final_level = input[1 + 2 * root]
    let final_entries = input[2 + 2 * root]
    if final_level > 0 and final_entries == 0: final_level = 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24: return -2
    for i in range(24): output[i] = 0
    output[0] = UInt8(root)
    output[8] = UInt8(final_level)
    output[16] = UInt8(final_entries)
    return 24
