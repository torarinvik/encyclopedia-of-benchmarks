from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn factoring_log_constant(bit: Int) -> UInt64:
    if bit == 2: return UInt64(0xd3cfd984)
    if bit == 3: return UInt64(0x9ee62e18)
    if bit == 4: return UInt64(0xe83d9070)
    if bit == 5: return UInt64(0xb59e81e0)
    if bit == 6: return UInt64(0xa17407c0)
    if bit == 7: return UInt64(0xce601f80)
    if bit == 8: return UInt64(0xf4807f00)
    if bit == 9: return UInt64(0xe701fe00)
    if bit == 10: return UInt64(0xbe07fc00)
    if bit == 11: return UInt64(0xfc1ff800)
    if bit == 12: return UInt64(0xf87ff000)
    if bit == 13: return UInt64(0xf1ffe000)
    if bit == 14: return UInt64(0xe7ffc000)
    if bit == 15: return UInt64(0xdfff8000)
    return UInt64(1) << UInt(bit)

fn factoring_mask(d: Int) -> UInt64:
    if d == 32: return UInt64(0xffffffff)
    return (UInt64(1) << UInt(d)) - UInt64(1)

fn factoring_log(remainder_input: UInt64, value_input: UInt64, d: Int,
                 modulus: UInt64, mask: UInt64) -> UInt64:
    var remainder = remainder_input
    var value = value_input
    for bit in range(2, d):
        if (value & (UInt64(1) << UInt(bit))) != 0:
            value = (value + (value << UInt(bit))) & mask
            remainder = (remainder + modulus - (factoring_log_constant(bit) & mask)) & mask
    return remainder

fn factoring_exp(remainder_input: UInt64, exponent_input: UInt64, d: Int,
                 modulus: UInt64, mask: UInt64) -> UInt64:
    var remainder = remainder_input
    var exponent = exponent_input
    for bit in range(2, d):
        if (exponent & (UInt64(1) << UInt(bit))) != 0:
            remainder = (remainder + (remainder << UInt(bit))) & mask
            exponent = (exponent + modulus - (factoring_log_constant(bit) & mask)) & mask
    return remainder

@export("factoring_exponentiation")
fn factoring_exponentiation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4:
        return -1
    let remainder_input = input[0]
    let base_input = input[1]
    let exponent_input = input[2]
    let d_input = input[3]
    if d_input < 3 or d_input > 32 or remainder_input < 0 or base_input < 1 or
        exponent_input < 0 or exponent_input > 4294967295:
        return -1
    let d = Int(d_input)
    let mask = factoring_mask(d)
    let modulus = mask + UInt64(1)
    var remainder = UInt64(remainder_input)
    var base = UInt64(base_input)
    let exponent = UInt64(exponent_input)
    if remainder >= modulus or base >= modulus or (base & UInt64(1)) == 0:
        return -1
    if (base & UInt64(2)) != 0:
        base = (modulus - base) & mask
        if (exponent & UInt64(1)) != 0:
            remainder = (modulus - remainder) & mask
    let log_value = factoring_log(UInt64(0), base, d, modulus, mask)
    let scaled_log = (log_value * exponent) & mask
    return Int64(factoring_exp(remainder, scaled_log, d, modulus, mask))
