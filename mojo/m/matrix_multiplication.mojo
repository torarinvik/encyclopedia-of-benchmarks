from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn matrix_mul_store(out: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for b in range(8): out[pos+b] = UInt8((bits >> UInt64(8*b)) & 255)

@export("matrix_multiplication")
fn matrix_multiplication(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 1: return -2
    let d = v[0]
    if d < 2 or d > 8: return -2
    let dim = Int(d); let cells = dim*dim
    if n != c_size_t(1 + 2*cells): return -2
    for i in range(2*cells):
        if v[1+i] < -1000 or v[1+i] > 1000: return -2
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(cells*8): return -3
    var result = InlineArray[Int64, 64](fill=0)
    for r in range(dim):
        for c in range(dim):
            var sum: Int64 = 0
            for k in range(dim): sum += v[1+r*dim+k] * v[1+cells+k*dim+c]
            result[r*dim+c] = sum
    for i in range(cells): matrix_mul_store(out, i*8, result[i])
    return Int64(cells)
