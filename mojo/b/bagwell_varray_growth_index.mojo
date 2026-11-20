from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 321
comptime MAX_Q = 256
comptime DATA_SLOTS = 352
comptime POINTER_SLOTS = 56
comptime LEVEL_HEADERS = 3

fn level_start(level: Int) -> Int:
    if level == 0:
        return 0
    if level == 1:
        return 64
    return 320

fn locate(level: Int, index: Int) -> Tuple[Int, Int, Int]:
    let start = level_start(level)
    var side = 8
    var pointer_start = 0
    if level == 1:
        side = 16
        pointer_start = 8
    elif level == 2:
        side = 32
        pointer_start = 24
    let relative = index - start
    let child = relative // side
    return (pointer_start + child, start + child * side, relative % side)

fn put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
        value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits >>= 8

@export("bagwell_varray_growth_index")
fn bagwell_varray_growth_index(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 580:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 0 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if (n == 0 and q != 0) or length != c_size_t(2 + n + q):
        return -1
    let query_start = 2 + n
    for j in range(q):
        let index = input[query_start + j]
        if index < 0 or index >= n_value:
            return -1

    var data = InlineArray[Int64, DATA_SLOTS](fill=0)
    var pointers = InlineArray[Int64, POINTER_SLOTS](fill=-1)
    var previous_header = InlineArray[Int64, LEVEL_HEADERS](fill=-1)
    var current_header = 0
    for index in range(n):
        if index == 64 or index == 320:
            let next_header = current_header + 1
            previous_header[next_header] = Int64(current_header)
            current_header = next_header
        let (slot, base, offset) = locate(current_header, index)
        if pointers[slot] == -1:
            pointers[slot] = Int64(base)
        if pointers[slot] != Int64(base) or base + offset >= DATA_SLOTS:
            return -1
        data[Int(pointers[slot]) + offset] = input[2 + index]

    let output_bytes = 8 * (q + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    put_i64_le(output, 0, q_value)
    for j in range(q):
        let index = Int(input[query_start + j])
        var level = current_header
        while index < level_start(level):
            level = Int(previous_header[level])
        let (slot, _, offset) = locate(level, index)
        let base = Int(pointers[slot])
        put_i64_le(output, 8 * (j + 1), data[base + offset])
    return Int64(output_bytes)
