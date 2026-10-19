from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn fundamental_feed(h_input: UInt64, x: Int64) -> UInt64:
    var h = h_input
    let u = UInt64(x)
    for b in range(8):
        h ^= UInt64(UInt8((u >> (8 * b)) & 255))
        h *= 0x100000001b3
    return h

@export("first_fundamental_form")
fn first_fundamental_form(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 18: return -1
    for i in range(18):
        if v[i] < -100 or v[i] > 100: return -1
    var ru = InlineArray[Int64, 9](0)
    var rv = InlineArray[Int64, 9](0)
    var coeffs = InlineArray[Int64, 18](0)
    for k in range(3):
        let base = 6 * k
        ru[3 * k] = v[base + 1]
        ru[3 * k + 1] = 2 * v[base + 3]
        ru[3 * k + 2] = v[base + 4]
        rv[3 * k] = v[base + 2]
        rv[3 * k + 1] = v[base + 4]
        rv[3 * k + 2] = 2 * v[base + 5]
    for k in range(3):
        let a0=ru[3*k]; let a1=ru[3*k+1]; let a2=ru[3*k+2]
        let b0=rv[3*k]; let b1=rv[3*k+1]; let b2=rv[3*k+2]
        var base = 0
        coeffs[base] += a0*a0; coeffs[base+1] += 2*a0*a1; coeffs[base+2] += 2*a0*a2
        coeffs[base+3] += a1*a1; coeffs[base+4] += 2*a1*a2; coeffs[base+5] += a2*a2
        base = 6
        coeffs[base] += a0*b0; coeffs[base+1] += a0*b1+a1*b0; coeffs[base+2] += a0*b2+a2*b0
        coeffs[base+3] += a1*b1; coeffs[base+4] += a1*b2+a2*b1; coeffs[base+5] += a2*b2
        base = 12
        coeffs[base] += b0*b0; coeffs[base+1] += 2*b0*b1; coeffs[base+2] += 2*b0*b2
        coeffs[base+3] += b1*b1; coeffs[base+4] += 2*b1*b2; coeffs[base+5] += b2*b2
    var hash: UInt64 = 0xcbf29ce484222325
    for i in range(18): hash = fundamental_feed(hash, coeffs[i])
    return Int64(hash)
