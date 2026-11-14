from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn dbms_union_volume(input: UnsafePointer[Int64, ImmutAnyOrigin], left: Int, right: Int) -> Int64:
    var volume: Int64 = 1
    for d in range(4):
        var lower = input[left + d]
        var upper = input[left + 4 + d]
        if input[right + d] < lower: lower = input[right + d]
        if input[right + 4 + d] > upper: upper = input[right + 4 + d]
        volume *= upper - lower
    return volume

fn dbms_seed_volume(input: UnsafePointer[Int64, ImmutAnyOrigin], at: Int) -> Int64:
    var volume: Int64 = 1
    for d in range(4): volume *= input[at + 4 + d] - input[at + d]
    return volume

@export("versabench_dbms_partition_entries")
fn versabench_dbms_partition_entries(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 74: return -1
    if input[0] < 2 or input[0] > 8: return -1
    let fan = Int(input[0])
    let count = fan + 1
    if Int(length) != 1 + 8 * count: return -1
    for i in range(count):
        let base = 1 + 8 * i
        for d in range(4):
            let lower = input[base + d]
            let upper = input[base + 4 + d]
            if lower < -8 or lower > 8 or upper < -8 or upper > 8 or lower >= upper: return -1
    var seed_a = 0
    var seed_b = 1
    var largest: Int64 = 0
    for i in range(count):
        for j in range(i + 1, count):
            let candidate = dbms_union_volume(input, 1 + 8 * i, 1 + 8 * j)
            if candidate > largest:
                largest = candidate
                seed_a = i
                seed_b = j
    let a = 1 + 8 * seed_a
    let b = 1 + 8 * seed_b
    let volume_a = dbms_seed_volume(input, a)
    let volume_b = dbms_seed_volume(input, b)
    var size_a = 1
    var size_b = 1
    var mask: Int64 = Int64(1) << seed_a
    for i in range(count):
        if i == seed_a or i == seed_b: continue
        var to_a = False
        if size_a < fan and size_b < fan:
            let at = 1 + 8 * i
            to_a = dbms_union_volume(input, a, at) - volume_a < dbms_union_volume(input, b, at) - volume_b
        elif size_b >= fan and size_a < fan:
            to_a = True
        elif size_a >= fan and size_b >= fan:
            return -1
        if to_a:
            mask |= Int64(1) << i
            size_a += 1
        else:
            size_b += 1
    return mask
