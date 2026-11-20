from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

from std.collections import InlineArray

const MAX_H = 32
const MAX_W = 32
const MAX_Q = 128
const MAX_INPUT = 1540
const MAX_OUTPUT = 1024
const MODULUS = 1_000_000_007
const ROW_BASE = 31
const COL_BASE = 37

@export("rolling_hash_2d_rectangle_query")
fn rolling_hash_2d_rectangle_query(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT:
        return -1
    let h_value = input[0]
    let w_value = input[1]
    let q_value = input[2]
    if h_value < 1 or h_value > MAX_H or w_value < 1 or w_value > MAX_W
        or q_value < 1 or q_value > MAX_Q:
        return -1
    let h = Int(h_value)
    let w = Int(w_value)
    let q = Int(q_value)
    if length != c_size_t(3 + h*w + 4*q):
        return -1
    let query_offset = 3 + h*w
    for i in range(h*w):
        if input[3+i] < 0 or input[3+i] > 255:
            return -1
    for i in range(q):
        let r0 = input[query_offset + 4*i]
        let c0 = input[query_offset + 4*i + 1]
        let r1 = input[query_offset + 4*i + 2]
        let c1 = input[query_offset + 4*i + 3]
        if r0 < 0 or r0 > r1 or r1 > h_value or c0 < 0 or c0 > c1 or c1 > w_value:
            return -1
    let required = 8*q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    var row_power = InlineArray[Int64, MAX_H + 1](fill=0)
    var col_power = InlineArray[Int64, MAX_W + 1](fill=0)
    row_power[0] = 1
    col_power[0] = 1
    for i in range(1, h + 1): row_power[i] = row_power[i - 1] * ROW_BASE % MODULUS
    for j in range(1, w + 1): col_power[j] = col_power[j - 1] * COL_BASE % MODULUS
    var prefix = InlineArray[Int64, (MAX_H + 1) * (MAX_W + 1)](fill=0)
    for r in range(1, h + 1):
        var row_hash: Int64 = 0
        for c in range(1, w + 1):
            row_hash = (row_hash * COL_BASE + input[3 + (r - 1)*w + c - 1]) % MODULUS
            prefix[r*(MAX_W + 1) + c] =
                (prefix[(r - 1)*(MAX_W + 1) + c] * ROW_BASE + row_hash) % MODULUS
    var staged = InlineArray[UInt8, MAX_OUTPUT](fill=0)
    for i in range(q):
        let r0 = Int(input[query_offset + 4*i])
        let c0 = Int(input[query_offset + 4*i + 1])
        let r1 = Int(input[query_offset + 4*i + 2])
        let c1 = Int(input[query_offset + 4*i + 3])
        let rh = r1-r0
        let cw = c1-c0
        var value = prefix[r1*(MAX_W + 1) + c1]
            - prefix[r0*(MAX_W + 1) + c1] * row_power[rh] % MODULUS
            - prefix[r1*(MAX_W + 1) + c0] * col_power[cw] % MODULUS
            + prefix[r0*(MAX_W + 1) + c0] * row_power[rh] % MODULUS * col_power[cw] % MODULUS
        value %= MODULUS
        if value < 0: value += MODULUS
        let bits = UInt64(value)
        for byte in range(8):
            output[8*i + byte] = UInt8((bits >> (8*byte)) & 255)
    return Int64(required)
