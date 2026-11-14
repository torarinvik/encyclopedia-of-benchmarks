# Clean-room Montgomery product; source provenance is in the package README.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn mont_wide(a: UInt64, b: UInt64) -> (UInt64, UInt64):
    let mask: UInt64 = 0xffffffff
    let a0 = a & mask; let a1 = a >> 32
    let b0 = b & mask; let b1 = b >> 32
    let first = a0*b0
    let low = first & mask
    let middle = a1*b0 + (first >> 32)
    let other = a0*b1 + (middle & mask)
    let high = a1*b1 + (middle >> 32) + (other >> 32)
    return high, ((other & mask) << 32) | low

fn mont_low(a: UInt64, b: UInt64) -> UInt64:
    let _, low = mont_wide(a, b)
    return low

@export("embench_aha_mont64")
fn embench_aha_mont64(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    if input[0] < 0 or input[1] < 0 or input[2] < 3 or (input[2] & 1) == 0: return -1
    let a = UInt64(input[0]); let b = UInt64(input[1]); let modulus = UInt64(input[2])
    if a >= modulus or b >= modulus: return -1
    # Newton iteration computes the inverse modulo 2^64; multiplication is
    # explicitly reduced through the low half of a limb product.
    var inverse: UInt64 = 1
    for _ in range(6):
        let product = mont_low(modulus, inverse)
        var correction: UInt64 = 0
        if product <= 2: correction = 2-product
        else: correction = (~product)+3
        inverse = mont_low(inverse, correction)
    let negative_inverse = (~inverse)+1
    let high, low = mont_wide(a, b)
    let multiplier = mont_low(low, negative_inverse)
    let add_high, add_low = mont_wide(multiplier, modulus)
    # The low halves sum to zero modulo 2^64; a nonzero low half
    # therefore contributes exactly one carry into the upper half.
    var reduced = high + add_high
    if low != 0 and add_low != 0: reduced += 1
    if reduced >= modulus: reduced -= modulus
    return Int64(reduced)
