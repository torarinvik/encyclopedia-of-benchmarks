from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_CARDS = 12
comptime MAX_INPUT_WORDS = 14
comptime DECK_SIZE = 81

fn complement_code(a_raw: Int8, b_raw: Int8) -> Int:
    let a = Int(a_raw)
    let b = Int(b_raw)
    var result = 0
    var place = 1
    for _ in range(4):
        let digit_sum = (a // place) % 3 + (b // place) % 3
        result += ((3 - digit_sum % 3) % 3) * place
        place *= 3
    return result

fn put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[word * 8 + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("set_puzzle_find_sets")
fn set_puzzle_find_sets(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_WORDS:
        return -1
    let raw_count = input[0]
    if raw_count < 0 or raw_count > MAX_CARDS or length != c_size_t(raw_count + 1):
        return -1

    var index_by_code = InlineArray[Int8, DECK_SIZE](fill= -1)
    var code_by_index = InlineArray[Int8, MAX_CARDS](fill=0)
    let count = Int(raw_count)
    for i in range(count):
        let code = input[i + 1]
        if code < 0 or code >= DECK_SIZE: return -1
        let code_index = Int(code)
        if index_by_code[code_index] >= 0: return -1
        index_by_code[code_index] = Int8(i)
        code_by_index[i] = Int8(code)

    var set_count = 0
    for i in range(count):
        for j in range(i + 1, count):
            let k = index_by_code[complement_code(code_by_index[i], code_by_index[j])]
            if k > Int8(j): set_count += 1
    let output_bytes = (1 + 3 * set_count) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    put_i64_le(output, 0, Int64(set_count))
    var word = 1
    for i in range(count):
        for j in range(i + 1, count):
            let k = index_by_code[complement_code(code_by_index[i], code_by_index[j])]
            if k > Int8(j):
                put_i64_le(output, word, Int64(i))
                put_i64_le(output, word + 1, Int64(j))
                put_i64_le(output, word + 2, Int64(k))
                word += 3
    return Int64(output_bytes)
