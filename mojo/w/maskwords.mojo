from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mask_word_char(c: Int64) -> Bool:
    return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95

fn mask_target(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int, size: Int,
               position: Int, case_mode: Int) -> Int:
    # case_mode permits lowercase only, uppercase only, or an initial capital.
    for candidate in range(3):
        let width = 5 if candidate == 0 else 6
        if position + width > size: continue
        var match = True
        for i in range(width):
            var expected: Int64 = 0
            if candidate == 0:
                let letters = InlineArray[Int64, 5](98, 105, 114, 100, 115)
                expected = letters[i]
            elif candidate == 1:
                let letters = InlineArray[Int64, 6](109, 97, 114, 107, 101, 116)
                expected = letters[i]
            else:
                let letters = InlineArray[Int64, 6](115, 116, 114, 101, 101, 116)
                expected = letters[i]
            if case_mode == 1 or (case_mode == 2 and i == 0): expected -= 32
            if input[start + position + i] != expected: match = False
        if match: return width
    return 0

@export("maskwords")
fn maskwords(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 531: return -1
    if input[0] < 0 or input[0] > 512: return -1
    let text_size = Int(input[0])
    let mask_index = 1 + text_size
    if mask_index >= Int(length) or input[mask_index] < 0 or input[mask_index] > 16: return -1
    let mask_size = Int(input[mask_index])
    if Int(length) != mask_index + 1 + mask_size: return -1
    for i in range(text_size):
        if input[1 + i] < 1 or input[1 + i] > 127: return -1
    for i in range(mask_size):
        let value = input[mask_index + 1 + i]
        if value < 32 or value > 126 or value == 92: return -1
    var staged = InlineArray[UInt8, 1447](fill=0)
    var used = 0
    var start = 0
    var have_token = False
    while start < text_size:
        var end = start
        while end < text_size and input[1 + end] != 32: end += 1
        if have_token:
            staged[used] = 32
            used += 1
        let size = end - start
        var normalized = False
        for case_mode in range(3):
            if mask_target(input, 1 + start, size, 0, case_mode) == size and size > 0:
                normalized = True
        var pos = 0
        while pos < size:
            var matched = 0
            if normalized:
                matched = size
            else:
                let width = mask_target(input, 1 + start, size, pos, 0)
                if width > 0 and (pos == 0 or not mask_word_char(input[start + pos])) and (pos + width == size or not mask_word_char(input[1 + start + pos + width])):
                    matched = width
            if matched > 0:
                for i in range(mask_size):
                    staged[used] = UInt8(input[mask_index + 1 + i])
                    used += 1
                pos += matched
            else:
                let c = input[1 + start + pos]
                if c != 10:
                    staged[used] = UInt8(c)
                    used += 1
                pos += 1
        have_token = True
        if end == text_size: break
        start = end + 1
    if capacity < c_size_t(used) or (used > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for i in range(used): output[i] = staged[i]
    return Int64(used)
