from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn autokey_upper(value: Int64) -> Int64:
    if value >= 97 and value <= 122: return value - 32
    return value

@export("autokey_cipher")
fn autokey_cipher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 2052: return -1
    let mode = input[0]
    let dialect = input[1]
    let text_len = input[2]
    let key_len = input[3]
    if (mode != 0 and mode != 1) or (dialect != 0 and dialect != 1) or text_len < 1 or text_len > 1024 or key_len < 1 or key_len > 1024 or length != c_size_t(4 + text_len + key_len): return -1
    let key_start = 4 + Int(text_len)
    for i in range(Int(text_len)):
        let ch = input[4 + i]
        if not ((ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122)) or (dialect == 1 and mode == 1 and ch >= 65 and ch <= 90): return -1
    for i in range(Int(key_len)):
        let ch = input[key_start + i]
        if not ((ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122)): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(text_len): return -2
    for i in range(Int(text_len)):
        let plain = autokey_upper(input[4 + i]) - 65
        var key_value: Int64 = 0
        if i < Int(key_len):
            key_value = autokey_upper(input[key_start + i])
        elif mode == 0:
            key_value = autokey_upper(input[4 + i - Int(key_len)])
        else:
            key_value = autokey_upper(Int64(output[i - Int(key_len)]))
        let shift = key_value - 65
        var mapped = (plain + shift) % 26
        if mode == 1: mapped = (plain - shift + 26) % 26
        var result = 65 + mapped
        if dialect == 1: result += 32
        output[i] = UInt8(result)
    return text_len
