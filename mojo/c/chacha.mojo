from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn rotate_left(value: UInt64, count: UInt64) -> UInt64:
    return ((value << count) | (value >> (32 - count))) & 0xffffffff

fn quarter_round(a_arg: UInt64, b_arg: UInt64, c_arg: UInt64, d_arg: UInt64) -> (UInt64, UInt64, UInt64, UInt64):
    var a = a_arg
    var b = b_arg
    var c = c_arg
    var d = d_arg
    a = (a + b) & 0xffffffff
    d = rotate_left(d ^ a, 16)
    c = (c + d) & 0xffffffff
    b = rotate_left(b ^ c, 12)
    a = (a + b) & 0xffffffff
    d = rotate_left(d ^ a, 8)
    c = (c + d) & 0xffffffff
    b = rotate_left(b ^ c, 7)
    return (a, b, c, d)

@export("chacha")
fn chacha(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 16: return -1
    var initial = InlineArray[UInt64, 16](0)
    for i in range(16):
        if input[i] < 0 or input[i] > 4294967295: return -1
        initial[i] = UInt64(input[i])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < 64: return -2
    var state = initial
    for _ in range(10):
        var (a, b, c, d) = quarter_round(state[0], state[4], state[8], state[12])
        state[0] = a; state[4] = b; state[8] = c; state[12] = d
        (a, b, c, d) = quarter_round(state[1], state[5], state[9], state[13])
        state[1] = a; state[5] = b; state[9] = c; state[13] = d
        (a, b, c, d) = quarter_round(state[2], state[6], state[10], state[14])
        state[2] = a; state[6] = b; state[10] = c; state[14] = d
        (a, b, c, d) = quarter_round(state[3], state[7], state[11], state[15])
        state[3] = a; state[7] = b; state[11] = c; state[15] = d
        (a, b, c, d) = quarter_round(state[0], state[5], state[10], state[15])
        state[0] = a; state[5] = b; state[10] = c; state[15] = d
        (a, b, c, d) = quarter_round(state[1], state[6], state[11], state[12])
        state[1] = a; state[6] = b; state[11] = c; state[12] = d
        (a, b, c, d) = quarter_round(state[2], state[7], state[8], state[13])
        state[2] = a; state[7] = b; state[8] = c; state[13] = d
        (a, b, c, d) = quarter_round(state[3], state[4], state[9], state[14])
        state[3] = a; state[4] = b; state[9] = c; state[14] = d
    var staged = InlineArray[UInt8, 64](0)
    for i in range(16):
        let word = (state[i] + initial[i]) & 0xffffffff
        staged[4 * i] = UInt8(word & 255)
        staged[4 * i + 1] = UInt8((word >> 8) & 255)
        staged[4 * i + 2] = UInt8((word >> 16) & 255)
        staged[4 * i + 3] = UInt8((word >> 24) & 255)
    for i in range(64): output[i] = staged[i]
    return 64
