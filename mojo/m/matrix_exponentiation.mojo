from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn me_mul(a: InlineArray[Int64,64], b: InlineArray[Int64,64], order: Int) -> InlineArray[Int64,64]:
    var c = InlineArray[Int64,64](fill=0)
    for r in range(order):
        for col in range(order):
            for k in range(order): c[r*8+col] = (c[r*8+col] + (a[r*8+k]*b[k*8+col])%1_000_000_007)%1_000_000_007
    return c

fn me_power(a: InlineArray[Int64,64], exponent: Int64, order: Int) -> InlineArray[Int64,64]:
    if exponent == 1: return a
    if exponent % 2 == 1: return me_mul(a, me_power(a, exponent-1, order), order)
    let half = me_power(a, exponent/2, order)
    return me_mul(half,half,order)

@export("matrix_exponentiation")
fn matrix_exponentiation(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 1 or n > 18: return -1
    let order = Int(v[0])
    if order < 1 or order > 8 or n != c_size_t(2*order+2): return -1
    for i in range(2*order):
        if v[1+i] < 0 or v[1+i] >= 1_000_000_007: return -1
    let exponent = v[2*order+1]
    if exponent < 0 or exponent > 1_000_000_000_000: return -1
    if exponent == 0: return 0
    if exponent <= order: return v[Int(exponent)]
    var transition = InlineArray[Int64,64](fill=0)
    for i in range(order-1): transition[i*8+i+1] = 1
    for col in range(order): transition[(order-1)*8+col] = v[order+1+order-1-col]
    let powered = me_power(transition, exponent-1, order)
    var result: Int64 = 0
    for i in range(order): result = (result + (powered[i]*v[1+i])%1_000_000_007)%1_000_000_007
    return result
