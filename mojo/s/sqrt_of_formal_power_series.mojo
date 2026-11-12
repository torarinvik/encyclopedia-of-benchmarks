from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime FPS_MODULUS: Int64 = 998244353
comptime FPS_MAX_N = 64
comptime FPS_MAX_INPUT = 66

fn fps_mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value % FPS_MODULUS
    var exponent = exponent_value
    var result = Int64(1)
    while exponent > 0:
        if exponent % 2 != 0: result = result * base % FPS_MODULUS
        base = base * base % FPS_MODULUS
        exponent //= 2
    return result

fn fps_mod_sqrt(value: Int64) -> Int64:
    if value == 0: return 0
    if fps_mod_pow(value, (FPS_MODULUS - 1) // 2) != 1: return -1
    var odd_part = FPS_MODULUS - 1
    var twos = Int(0)
    while odd_part % 2 == 0:
        odd_part //= 2
        twos += 1
    var non_residue = Int64(2)
    while fps_mod_pow(non_residue, (FPS_MODULUS - 1) // 2) != FPS_MODULUS - 1:
        non_residue += 1
    var c = fps_mod_pow(non_residue, odd_part)
    var root = fps_mod_pow(value, (odd_part + 1) // 2)
    var remainder = fps_mod_pow(value, odd_part)
    var order = twos
    while remainder != 1:
        var index = Int(1)
        var probe = remainder * remainder % FPS_MODULUS
        while index < order and probe != 1:
            probe = probe * probe % FPS_MODULUS
            index += 1
        if index >= order or probe != 1: return -1
        var exponent = Int64(1)
        for bit in range(order - index - 1): exponent *= 2
        let factor = fps_mod_pow(c, exponent)
        root = root * factor % FPS_MODULUS
        let factor_squared = factor * factor % FPS_MODULUS
        remainder = remainder * factor_squared % FPS_MODULUS
        c = factor_squared
        order = index
    return root if root < FPS_MODULUS - root else FPS_MODULUS - root

fn fps_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("sqrt_of_formal_power_series")
fn sqrt_of_formal_power_series(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > FPS_MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > FPS_MAX_N:
        return -1
    let n = Int(n_value)
    if Int(length) != n + 1:
        return -1
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] >= FPS_MODULUS:
            return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2

    var result = InlineArray[Int64, FPS_MAX_N]()
    var valuation = Int(0)
    while valuation < n and input[valuation + 1] == 0:
        valuation += 1
    if valuation == n:
        for i in range(n): fps_store_le(output, 8 * i, 0)
        return Int64(bytes)
    if valuation % 2 != 0:
        fps_store_le(output, 0, -1)
        return 8
    let shift = valuation // 2
    let leading_root = fps_mod_sqrt(input[valuation + 1])
    if leading_root < 0:
        fps_store_le(output, 0, -1)
        return 8
    let inverse_twice_root = fps_mod_pow((2 * leading_root) % FPS_MODULUS, FPS_MODULUS - 2)
    let width = n - valuation
    result[shift] = leading_root
    for degree in range(1, width):
        var cross_terms = Int64(0)
        for i in range(1, degree):
            cross_terms = (cross_terms + result[shift + i] * result[shift + degree - i]) % FPS_MODULUS
        var delta = (input[valuation + degree + 1] - cross_terms) % FPS_MODULUS
        if delta < 0: delta += FPS_MODULUS
        result[shift + degree] = delta * inverse_twice_root % FPS_MODULUS
    for i in range(n): fps_store_le(output, 8 * i, result[i])
    return Int64(bytes)
