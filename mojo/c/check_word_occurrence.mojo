from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn is_space(c: UInt8) -> Bool:
    return (c >= 9 and c <= 13) or c == 32

fn lower_byte(c: UInt8) -> UInt8:
    return c + 32 if c >= 65 and c <= 90 else c

fn token_is_forbidden(text: InlineArray[UInt8, 1024], start: Int64, token_length: Int64) -> Bool:
    if token_length == 11:
        let name = "constructor".as_bytes()
        var same = True
        for i in range(token_length):
            if lower_byte(text[start + i]) != name[i]: same = False
        if same: return True
    if token_length == 8:
        let name = "tostring".as_bytes()
        var same = True
        for i in range(token_length):
            if lower_byte(text[start + i]) != name[i]: same = False
        if same: return True
    if token_length == 14:
        let name = "tolocalestring".as_bytes()
        var same = True
        for i in range(token_length):
            if lower_byte(text[start + i]) != name[i]: same = False
        if same: return True
        let name2 = "hasownproperty".as_bytes()
        same = True
        for i in range(token_length):
            if lower_byte(text[start + i]) != name2[i]: same = False
        if same: return True
    if token_length == 7:
        let name = "valueof".as_bytes()
        var same = True
        for i in range(token_length):
            if lower_byte(text[start + i]) != name[i]: same = False
        if same: return True
    if token_length == 13:
        let name = "isprototypeof".as_bytes()
        var same = True
        for i in range(token_length):
            if lower_byte(text[start + i]) != name[i]: same = False
        if same: return True
    if token_length == 20:
        let name = "propertyisenumerable".as_bytes()
        var same = True
        for i in range(token_length):
            if lower_byte(text[start + i]) != name[i]: same = False
        if same: return True
    return False

@export("check_word_occurrence")
fn check_word_occurrence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 0 or input[0] > 1 or input[1] < 0 or input[1] > 1024 or length != input[1] + 2: return -1
    let lowercase_flag = input[0]
    let n = input[1]
    var text = InlineArray[UInt8, 1024](0)
    for i in range(n):
        let value = input[i + 2]
        if value < 0 or value > 127: return -1
        let byte = UInt8(value)
        if not ((byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) or is_space(byte)): return -1
        text[i] = lower_byte(byte) if lowercase_flag == 1 else byte
    var starts = InlineArray[Int64, 1025](0)
    var lengths = InlineArray[Int64, 1025](0)
    var counts = InlineArray[Int64, 1025](0)
    var entries: Int64 = 0
    var i: Int64 = 0
    var start: Int64 = 0
    while True:
        if i == n or is_space(text[i]):
            let token_length = i - start
            if token_is_forbidden(text, start, token_length): return -1
            var entry: Int64 = 0
            var found = False
            while entry < entries and not found:
                if lengths[entry] == token_length:
                    var same = True
                    for j in range(token_length):
                        if text[starts[entry] + j] != text[start + j]: same = False
                    if same: found = True
                if not found: entry += 1
            if not found:
                starts[entries] = start
                lengths[entries] = token_length
                counts[entries] = 0
                entry = entries
                entries += 1
            counts[entry] += 1
            if i == n: break
            while i < n and is_space(text[i]): i += 1
            start = i
        else:
            i += 1
    var required: Int64 = 4
    for entry in range(entries): required += 8 + lengths[entry]
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < required: return -2
    var pos: Int64 = 0
    let entry_count = UInt32(entries)
    for byte in range(4): output[pos + byte] = UInt8((entry_count >> (8 * byte)) & 255)
    pos += 4
    for entry in range(entries):
        let key_length = UInt32(lengths[entry])
        for byte in range(4): output[pos + byte] = UInt8((key_length >> (8 * byte)) & 255)
        pos += 4
        for j in range(lengths[entry]):
            output[pos] = text[starts[entry] + j]
            pos += 1
        let count = UInt32(counts[entry])
        for byte in range(4): output[pos + byte] = UInt8((count >> (8 * byte)) & 255)
        pos += 4
    return pos
