from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn mer_mul(a: InlineArray[Int64, 4], b: InlineArray[Int64, 4]) -> InlineArray[Int64, 4]:
    var c = InlineArray[Int64, 4](fill=0)
    for r in range(2):
        for col in range(2):
            for k in range(2): c[r*2+col] += a[r*2+k] * b[k*2+col]
    return c

fn mer_power(a: InlineArray[Int64, 4], e: Int) -> InlineArray[Int64, 4]:
    if e == 0: return InlineArray[Int64, 4](1,0,0,1)
    if e % 2 == 1: return mer_mul(mer_power(a, e-1), a)
    let half = mer_power(a, e / 2)
    return mer_mul(half, half)

fn mer_store(out: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for b in range(8): out[pos+b] = UInt8((bits >> UInt64(8*b)) & 255)

@export("matrix_exponentiation_recursive")
fn matrix_exponentiation_recursive(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 5 or v[0] < 0 or v[0] > 30: return -2
    for i in range(1, 5):
        if v[i] < -1 or v[i] > 1: return -2
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < 32: return -3
    let a = InlineArray[Int64, 4](v[1],v[2],v[3],v[4])
    let result = mer_power(a, Int(v[0]))
    for i in range(4): mer_store(out, i*8, result[i])
    return 4
