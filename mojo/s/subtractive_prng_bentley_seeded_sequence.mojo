from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
              value: Int32):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("subtractive_prng_bentley_seeded_sequence")
fn subtractive_prng_bentley_seeded_sequence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2:
        return -1
    let seed = input[0]
    let count = input[1]
    if seed < 0 or seed >= 1000000000 or count < 0 or count > 64:
        return -1
    let n = Int(count)
    let required = n * 8
    if capacity < c_size_t(required) or (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    if n == 0:
        return 0

    var seed_state = InlineArray[Int32, 55]()
    var ring = InlineArray[Int32, 55]()
    seed_state[0] = Int32(seed)
    seed_state[1] = 1
    for i in range(2, 55):
        var value = seed_state[i - 2] - seed_state[i - 1]
        if value < 0:
            value += 1000000000
        seed_state[i] = value
    for i in range(55):
        ring[i] = seed_state[(34 * (i + 1)) % 55]

    var write_index = 0
    var lag_index = 31
    for step in range(165 + n):
        var value = ring[write_index] - ring[lag_index]
        if value < 0:
            value += 1000000000
        ring[write_index] = value
        if step >= 165:
            put_i64_le(output, (step - 165) * 8, value)
        write_index = (write_index + 1) % 55
        lag_index = (lag_index + 1) % 55
    return Int64(required)
