from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime INVALID: Int64 = -2_147_483_649
@export("binary_pow")
fn binary_pow(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return INVALID
    let base_input = input[0]; let exp_input = input[1]
    if base_input < -2_147_483_648 or base_input > 2_147_483_647 or exp_input < -2_147_483_648 or exp_input > 2_147_483_647: return INVALID
    let normalized_base = base_input if base_input >= 0 else base_input + 4_294_967_296
    var base = UInt64(normalized_base)
    var exponent = exp_input
    var result: UInt64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = (result * base) & UInt64(0xFFFFFFFF)
        base = (base * base) & UInt64(0xFFFFFFFF)
        exponent >>= 1
    return Int64(result) if result < UInt64(0x80000000) else Int64(result) - 4_294_967_296
