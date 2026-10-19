from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn matrix_copy_store(out: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for b in range(8): out[pos+b] = UInt8((bits >> UInt64(8*b)) & 255)

@export("matrix_copy")
fn matrix_copy(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 1026: return -1
    let rows = v[0]; let cols = v[1]
    if rows < 0 or rows > 32 or cols < 0 or cols > 32 or n != c_size_t(2 + rows*cols): return -1
    let count = Int(rows*cols)
    for i in range(count):
        if v[2+i] < -2147483648 or v[2+i] > 2147483647: return -1
    let rr = 0 if rows == 0 or cols == 0 else Int(rows)
    let cc = 0 if rows == 0 or cols == 0 else Int(cols)
    let result_count = rr * cc; let bytes = (2 + result_count) * 8
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(bytes): return -2
    var staged = InlineArray[Int64, 1026](fill=0)
    staged[0] = Int64(rr); staged[1] = Int64(cc)
    for i in range(result_count): staged[i+2] = v[i+2]
    for i in range(2 + result_count): matrix_copy_store(out, i*8, staged[i])
    return Int64(bytes)
