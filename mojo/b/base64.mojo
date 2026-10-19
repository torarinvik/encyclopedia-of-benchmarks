from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn base64_value(ch: Int64) -> Int64:
    if ch >= 65 and ch <= 90: return ch - 65
    if ch >= 97 and ch <= 122: return ch - 71
    if ch >= 48 and ch <= 57: return ch + 4
    if ch == 43: return 62
    if ch == 47: return 63
    return -1

fn base64_char(value: Int) -> UInt8:
    if value < 26: return UInt8(65 + value)
    if value < 52: return UInt8(71 + value)
    if value < 62: return UInt8(value - 4)
    return UInt8(43 if value == 62 else 47)

@export("base64")
fn base64(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 66: return -1
    let mode = input[0]
    if mode != 0 and mode != 1: return -1
    let n = Int(length) - 1
    var out = List[UInt8](capacity=128)
    if mode == 0:
        var buffer: UInt32 = 0
        var bits = 0
        for i in range(n):
            let value = input[i + 1]
            if value < 0 or value > 255: return -1
            buffer = (buffer << 8) | UInt32(value)
            bits += 8
            while bits >= 6:
                bits -= 6
                out.append(base64_char(Int((buffer >> bits) & 63)))
        if bits > 0: out.append(base64_char(Int((buffer << (6 - bits)) & 63)))
        while len(out) % 4 != 0: out.append(UInt8(61))
    else:
        var data_length = n
        while data_length > 0 and input[data_length] == 61: data_length -= 1
        let padding = n - data_length
        let rem = data_length % 4
        if rem == 1: return -1
        let expected_pad = 0 if rem == 0 else (2 if rem == 2 else 1)
        if padding != 0 and (n % 4 != 0 or padding != expected_pad): return -1
        for i in range(data_length, n):
            if input[i + 1] != 61: return -1
        var buffer: UInt32 = 0
        var bits = 0
        for i in range(data_length):
            let digit = base64_value(input[i + 1])
            if digit < 0: return -1
            buffer = (buffer << 6) | UInt32(digit)
            bits += 6
            if bits >= 8:
                bits -= 8
                out.append(UInt8((buffer >> bits) & 255))
        if bits > 0 and (buffer & ((UInt32(1) << bits) - 1)) != 0: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(out)): return -2
    for i in range(len(out)): output[i] = out[i]
    return Int64(len(out))
