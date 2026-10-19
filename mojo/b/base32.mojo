from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn base32_value(ch: Int64) -> Int64:
    if ch >= 65 and ch <= 90: return ch - 65
    if ch >= 50 and ch <= 55: return ch - 24
    return -1

@export("base32")
fn base32(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 66: return -1
    let mode = input[0]
    if mode != 0 and mode != 1: return -1
    let n = Int(length) - 1
    var out = List[UInt8](capacity=128)
    if mode == 0:
        var buffer: UInt64 = 0
        var bits = 0
        for i in range(n):
            let value = input[i + 1]
            if value < 0 or value > 255: return -1
            buffer = (buffer << 8) | UInt64(value)
            bits += 8
            while bits >= 5:
                bits -= 5
                let digit = Int((buffer >> bits) & 31)
                out.append(UInt8(65 + digit) if digit < 26 else UInt8(24 + digit))
        if bits > 0:
            let digit = Int((buffer << (5 - bits)) & 31)
            out.append(UInt8(65 + digit) if digit < 26 else UInt8(24 + digit))
        while len(out) % 8 != 0: out.append(UInt8(61))
    else:
        var data_length = n
        while data_length > 0 and input[data_length] == 61: data_length -= 1
        let padding = n - data_length
        let rem = data_length % 8
        if not (rem == 0 or rem == 2 or rem == 4 or rem == 5 or rem == 7): return -1
        let expected_pad = 0 if rem == 0 else (6 if rem == 2 else (4 if rem == 4 else (3 if rem == 5 else 1)))
        if padding != 0 and (n % 8 != 0 or padding != expected_pad): return -1
        if padding == 0 and data_length != n: return -1
        for i in range(data_length, n):
            if input[i + 1] != 61: return -1
        var buffer: UInt64 = 0
        var bits = 0
        for i in range(data_length):
            let digit = base32_value(input[i + 1])
            if digit < 0: return -1
            buffer = (buffer << 5) | UInt64(digit)
            bits += 5
            if bits >= 8:
                bits -= 8
                out.append(UInt8((buffer >> bits) & 255))
        if bits > 0 and (buffer & ((UInt64(1) << bits) - 1)) != 0: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(out)): return -2
    for i in range(len(out)): output[i] = out[i]
    return Int64(len(out))
