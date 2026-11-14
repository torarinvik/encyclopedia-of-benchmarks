from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s343_column_major_compaction")
fn tsvc_s343_column_major_compaction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 130: return -1
    let rows0 = input[0]; let cols0 = input[1]
    if rows0 < 1 or rows0 > 8 or cols0 < 1 or cols0 > 8: return -1
    let rows = Int(rows0); let cols = Int(cols0); let cells = rows * cols
    if length != c_size_t(2 + 2 * cells): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * cells): return -2
    var written = 0
    for col in range(cols):
        for row in range(rows):
            let index = row * cols + col
            if input[2 + cells + index] > 0:
                let value = input[2 + index]
                for byte in range(8): output[8 * written + byte] = UInt8((value >> (8 * byte)) & 255)
                written += 1
    return Int64(written)
