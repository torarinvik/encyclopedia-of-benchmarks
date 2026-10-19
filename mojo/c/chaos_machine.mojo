from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import floor

fn fraction_one(value: Float64) -> Float64:
    return value - floor(value)

fn round_ten(value: Float64) -> Float64:
    if value <= 0.0: return 0.0
    let bits = bitcast[UInt64](value)
    let exponent = (bits >> 52) & 0x7ff
    if exponent == 0: return 0.0
    let mantissa = (UInt64(1) << 52) | (bits & ((UInt64(1) << 52) - 1))
    let low_product = (mantissa & 0xffffffff) * 9765625
    let high_product = (mantissa >> 32) * 9765625
    let shifted_high = high_product << 32
    let low = shifted_high + low_product
    var high = high_product >> 32
    if low < shifted_high: high += 1
    let shift = 1065 - Int64(exponent)
    if shift > 77: return 0.0
    var rounded: UInt64 = 0
    var relation: Int64 = 0
    if shift < 64:
        rounded = (high << UInt64(64 - shift)) | (low >> UInt64(shift))
        let remainder = low & ((UInt64(1) << UInt64(shift)) - 1)
        let half = UInt64(1) << UInt64(shift - 1)
        if remainder > half: relation = 1
        elif remainder < half: relation = -1
    elif shift == 64:
        rounded = high
        let half = UInt64(1) << 63
        if low > half: relation = 1
        elif low < half: relation = -1
    else:
        let upper_bits = shift - 64
        rounded = high >> UInt64(upper_bits)
        let remainder_high = high & ((UInt64(1) << UInt64(upper_bits)) - 1)
        let half_high = UInt64(1) << UInt64(upper_bits - 1)
        if remainder_high > half_high or (remainder_high == half_high and low != 0): relation = 1
        elif remainder_high < half_high: relation = -1
    if relation > 0 or (relation == 0 and (rounded & 1) != 0): rounded += 1
    return Float64(rounded) / 10000000000.0

@export("chaos_machine")
fn chaos_machine(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    let seed_count = values[0]
    if seed_count < 0 or seed_count > 64 or length != seed_count + 2: return -1
    let pull_count = values[length - 1]
    if pull_count < 0 or pull_count > 64: return -1
    for i in range(seed_count):
        if values[i + 1] < 0 or values[i + 1] > 1000000: return -1
    let required = 4 * pull_count
    if required > output_capacity or (required != 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var buffer = InlineArray[Float64, 5](0.0)
    buffer[0] = 0.33
    buffer[1] = 0.44
    buffer[2] = 0.55
    buffer[3] = 0.44
    buffer[4] = 0.33
    var params = InlineArray[Float64, 5](0.0)
    var machine_time: UInt64 = 0
    for seed_index in range(seed_count):
        let seed = Float64(values[seed_index + 1])
        for key in range(5):
            if buffer[key] == 0.0: return -1
            let evolution = seed / buffer[key]
            let value = fraction_one(buffer[(key + 1) % 5] + evolution)
            let rate = fraction_one(params[key] + evolution) + 3.0
            buffer[key] = round_ten(rate * value * (1.0 - value))
            params[key] = rate
        machine_time += 1
    var staged = InlineArray[UInt8, 256](0)
    for index in range(pull_count):
        let key = Int64(machine_time % 5)
        for _ in range(3):
            let rate = params[key]
            let value = buffer[key]
            buffer[key] = round_ten(rate * value * (1.0 - value))
            params[key] = fraction_one(Float64(machine_time) * 0.01 + rate * 1.01) + 3.0
        var x = UInt64(buffer[(key + 2) % 5] * 10000000000.0)
        var y = UInt64(buffer[(key + 3) % 5] * 10000000000.0)
        machine_time += 1
        x ^= y >> 13
        y ^= x << 17
        x ^= y >> 5
        let result = x & 0xffffffff
        for byte in range(4): staged[4 * index + byte] = UInt8((result >> (8 * byte)) & 255)
    for i in range(required): output[i] = staged[i]
    return required
