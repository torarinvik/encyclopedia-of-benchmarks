from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("table_compression_optimal_contiguous_partition")
fn table_compression_optimal_contiguous_partition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 66: return -1
    let rv = input[0]; let cv = input[1]
    if rv < 1 or rv > 8 or cv < 1 or cv > 8 or length != c_size_t(2 + rv * cv): return -1
    let rows = Int(rv); let cols = Int(cv)
    var table = InlineArray[Int64, 64](fill=0)
    for i in range(rows * cols):
        let value = input[2 + i]
        if value < 0 or value > 15: return -1
        table[i] = value
    var cost = InlineArray[Int64, 9](fill=0)
    var previous = InlineArray[Int, 9](fill=0)
    for end in range(1, cols + 1):
        cost[end] = 1000000
        for start in range(end):
            var runs: Int64 = 0
            var last: Int64 = -1
            for row in range(rows):
                for col in range(start, end):
                    let value = table[row * cols + col]
                    if value != last: runs += 1
                    last = value
            let candidate = cost[start] + 2 * runs
            if candidate < cost[end]:
                cost[end] = candidate
                previous[end] = start
    var groups: Int64 = 0
    var cuts: Int64 = 0
    var end = cols
    while end > 0:
        let start = previous[end]
        if start > 0: cuts |= Int64(1) << (start - 1)
        groups += 1
        end = start
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24: return -2
    for slot in range(3):
        let value = if slot == 0: cost[cols] elif slot == 1: groups else: cuts
        var bits = UInt64(value)
        for byte in range(8):
            output[8 * slot + byte] = UInt8(bits & 255)
            bits >>= 8
    return 24
