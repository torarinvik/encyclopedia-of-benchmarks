from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_PAYLOAD = 1024

fn python_code(upper: Int64) -> Int64:
    if upper >= 65 and upper <= 73: return upper - 65
    if upper == 74: return 28
    if upper >= 75 and upper <= 85: return upper - 66
    if upper == 86: return 29
    if upper >= 87 and upper <= 90: return upper - 67
    return -1

fn python_letter(code: Int64) -> Int64:
    if code >= 0 and code <= 8: return 97 + code
    if code == 28: return 106
    if code == 29: return 118
    if code >= 9 and code <= 19: return 97 + code + 1
    if code >= 20 and code <= 23: return 97 + code + 2
    return -1

fn decode_code(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int) -> Int64:
    var code: Int64 = 0
    for bit in range(5):
        code = (code << 1) | (1 if input[start + bit] == 66 else 0)
    return code

fn append_code(mut out: List[UInt8], code: Int64):
    for bit in range(4, -1, -1):
        out.append(UInt8(66 if ((code >> bit) & 1) != 0 else 65))

@export("baconian_cipher")
fn baconian_cipher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_PAYLOAD + 2:
        return -1
    let mode = input[0]
    let dialect = input[1]
    if (mode != 0 and mode != 1) or dialect < 0 or dialect > 2:
        return -1
    let n = Int(length) - 2
    for i in range(n):
        if input[i + 2] < 0 or input[i + 2] > 127:
            return -1
    var out = List[UInt8](capacity=MAX_PAYLOAD * 5)
    if mode == 0:
        for i in range(n):
            let value = input[i + 2]
            let upper = value - 32 if value >= 97 and value <= 122 else value
            let is_letter = upper >= 65 and upper <= 90
            if dialect == 0:
                if is_letter:
                    append_code(out, 9 if upper == 73 or upper == 74 else upper - 65)
            elif dialect == 1:
                if value == 32:
                    out.append(UInt8(32))
                elif is_letter:
                    let code = python_code(upper)
                    if code < 0: return -1
                    append_code(out, code)
                else:
                    return -1
            else:
                if is_letter:
                    if upper > 88: return -1
                    append_code(out, upper - 65)
                else:
                    out.append(UInt8(value))
    elif dialect == 0:
        if n % 5 != 0: return -1
        for i in range(n):
            if input[i + 2] != 65 and input[i + 2] != 66: return -1
        for i in range(0, n, 5):
            let code = decode_code(input, i + 2)
            if code > 25: return -1
            out.append(UInt8(73 if code == 8 or code == 9 else 65 + code))
    elif dialect == 1:
        var used: Int = 0
        var in_word = False
        for i in range(n):
            let value = input[i + 2]
            if value == 32:
                if used != 0: return -1
                in_word = False
            else:
                if value != 65 and value != 66: return -1
                in_word = True
                used += 1
                if used == 5:
                    if python_letter(decode_code(input, i - 2)) < 0: return -1
                    used = 0
        if used != 0: return -1
        var i: Int = 0
        var first_word = True
        while i < n:
            while i < n and input[i + 2] == 32: i += 1
            if i == n: break
            if not first_word: out.append(UInt8(32))
            first_word = False
            while i < n and input[i + 2] != 32:
                out.append(UInt8(python_letter(decode_code(input, i + 2))))
                i += 5
    else:
        for start in range(0, n, 5):
            if n - start < 5:
                out.append(UInt8(32))
            else:
                var valid = True
                for bit in range(5):
                    if input[start + bit + 2] != 65 and input[start + bit + 2] != 66:
                        valid = False
                let code = decode_code(input, start + 2)
                out.append(UInt8(65 + code) if valid and code < 24 else UInt8(32))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(out)):
        return -2
    for i in range(len(out)):
        output[i] = out[i]
    return Int64(len(out))
