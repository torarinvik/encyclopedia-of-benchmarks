from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn subsequence_store_u32(output: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: UInt32):
    for b in range(4):
        output[pos + b] = UInt8((value >> (8 * b)) & 255)

fn subsequence_generate(values: List[Int32], mut current: List[Int32], n: Int, index: Int,
                        current_len: Int, output: UnsafePointer[UInt8, MutAnyOrigin],
                        mut cursor: Int, mut emitted: Int):
    if index == n:
        subsequence_store_u32(output, cursor, UInt32(current_len))
        cursor += 4
        for i in range(current_len):
            subsequence_store_u32(output, cursor, UInt32(current[i]))
            cursor += 4
        emitted += 1
        return
    subsequence_generate(values, current, n, index + 1, current_len, output, cursor, emitted)
    current[current_len] = values[index]
    subsequence_generate(values, current, n, index + 1, current_len + 1, output, cursor, emitted)

@export("all_subsequences")
fn all_subsequences(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 9:
        return -1
    if input[0] < 0 or input[0] > 8 or length != c_size_t(input[0] + 1):
        return -1
    let n = Int(input[0])
    var values = List[Int32](length=n, fill=0)
    for i in range(n):
        if input[i + 1] < -2147483648 or input[i + 1] > 2147483647:
            return -1
        values[i] = Int32(input[i + 1])
    let rows = 1 << n
    var elements = 0
    if n != 0:
        elements = n * (rows / 2)
    let required = (rows + elements) * 4
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    var current = List[Int32](length=n, fill=0)
    var cursor = 0
    var emitted = 0
    subsequence_generate(values, current, n, 0, 0, output, cursor, emitted)
    return Int64(emitted)
