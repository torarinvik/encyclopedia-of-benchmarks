from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("crc_polynomial_division")
fn crc_polynomial_division(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 98: return -1
    let op = input[0]
    let raw_n = input[1]
    let raw_p = input[2]
    if op < 0 or op > 1 or raw_n < 1 or (op == 0 and raw_n > 64) or (op == 1 and raw_n > 79) or raw_p < 2 or raw_p > 16: return -1
    let n = raw_n
    let p = raw_p
    if length != 3 + n + p: return -1
    var message = InlineArray[UInt8, 79](0)
    var polynomial = InlineArray[UInt8, 16](0)
    var dividend = InlineArray[UInt8, 79](0)
    var remainder = InlineArray[UInt8, 16](0)
    for i in range(n):
        if input[3 + i] < 0 or input[3 + i] > 1: return -1
        message[i] = UInt8(input[3 + i])
        dividend[i] = message[i]
    for i in range(p):
        let bit = input[3 + n + i]
        if bit < 0 or bit > 1: return -1
        polynomial[i] = UInt8(bit)
    if polynomial[0] != 1 or polynomial[p - 1] != 1: return -1
    var dlen = n
    if op == 0:
        for i in range(p - 1):
            dividend[dlen] = 0
            dlen += 1
    var rem_len: Int64 = 0
    var cursor: Int64 = 0
    while cursor < dlen:
        while rem_len < p and cursor < dlen:
            remainder[rem_len] = dividend[cursor]
            rem_len += 1
            cursor += 1
        if rem_len == p:
            if remainder[0] == 1:
                for i in range(p): remainder[i] = remainder[i] ^ polynomial[i]
            var zeroes: Int64 = 0
            while zeroes < rem_len and remainder[zeroes] == 0: zeroes += 1
            for i in range(zeroes, rem_len): remainder[i - zeroes] = remainder[i]
            rem_len -= zeroes
    var stage = InlineArray[UInt8, 79](0)
    var out_len: Int64 = 0
    if op == 0:
        out_len = n + p - 1
        for i in range(n): stage[i] = message[i]
        let degree = p - 1
        let leading_zeroes = degree - rem_len
        for i in range(leading_zeroes): stage[n + i] = 0
        for i in range(rem_len): stage[n + leading_zeroes + i] = remainder[i]
    else:
        var nonzero = UInt8(0)
        for i in range(rem_len): nonzero |= remainder[i]
        stage[0] = 1 if nonzero != 0 else 0
        out_len = 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < out_len: return -2
    for i in range(out_len): output[i] = stage[i]
    return out_len
