from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn count_letters_lower(value: Int64) -> Int64:
    return value + 32 if value >= 65 and value <= 90 else value

@export("count_letters")
fn count_letters(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[1] < 0 or input[1] > 256: return -1
    let text_length = input[1]
    if length != text_length + 2: return -1
    let query = count_letters_lower(input[0])
    if query < 97 or query > 122: return -1
    var count: Int64 = 0
    for i in range(text_length):
        let value = input[i + 2]
        if not ((value >= 97 and value <= 122) or (value >= 65 and value <= 90)): return -1
        if count_letters_lower(value) == query: count += 1
    return count
