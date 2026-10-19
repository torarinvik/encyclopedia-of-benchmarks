from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn label_value(i: Int) -> Int64:
    if i == 0:
        return 65
    if i == 1:
        return 68
    if i == 2:
        return 70
    if i == 3:
        return 71
    if i == 4:
        return 86
    return 88

fn label_index(value: Int64) -> Int:
    for i in range(6):
        if value == label_value(i):
            return i
    return -1

fn polybius_cell(value: Int64) -> Int:
    let square: List[Int64] = [78,65,49,67,51,72,56,84,66,50,79,77,69,53,87,82,80,68,52,70,54,71,55,73,57,74,48,75,76,81,83,85,86,88,89,90]
    for i in range(36):
        if square[i] == value:
            return i
    return -1

fn adfgvx_compare_key(input: UnsafePointer[Int64, ImmutAnyOrigin], start: Int, a: Int, b: Int) -> Bool:
    return input[start + a] > input[start + b]

@export("adfgvxcipher")
fn adfgvxcipher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3:
        return -1
    let mode = input[0]
    let text_len = input[1]
    let key_len = input[2]
    if (mode != 0 and mode != 1) or text_len < 0 or key_len < 1 or key_len > 16:
        return -1
    if (mode == 0 and text_len > 256) or (mode == 1 and text_len > 512) or length != c_size_t(3 + text_len + key_len):
        return -1
    for i in range(text_len):
        if input[3 + i] < 0 or input[3 + i] > 127:
            return -1
        if mode == 1 and label_index(input[3 + i]) < 0:
            return -1
    if mode == 1 and text_len % 2 != 0:
        return -1
    let key_start = Int(3 + text_len)
    for i in range(key_len):
        let c = input[key_start + i]
        if c < 65 or c > 90:
            return -1
        for j in range(i):
            if c == input[key_start + j]:
                return -1
    var order = List[Int](length=Int(key_len), fill=0)
    for i in range(key_len):
        order[i] = i
    for i in range(1, key_len):
        let current = order[i]
        var j = i
        while j > 0 and adfgvx_compare_key(input, key_start, order[j - 1], current):
            order[j] = order[j - 1]
            j -= 1
        order[j] = current
    var result = List[UInt8](capacity=512)
    if mode == 0:
        var fractionated = List[Int64](capacity=512)
        for i in range(text_len):
            var c = input[3 + i]
            if c >= 97 and c <= 122:
                c -= 32
            if not ((c >= 65 and c <= 90) or (c >= 48 and c <= 57)):
                continue
            let cell = polybius_cell(c)
            if cell < 0:
                return -1
            fractionated.append(label_value(cell / 6))
            fractionated.append(label_value(cell % 6))
        var rows = 0
        if len(fractionated) > 0:
            rows = (len(fractionated) + Int(key_len) - 1) / Int(key_len)
        var table = List[Int64](length=512 * 16, fill=95)
        for i in range(len(fractionated)):
            table[(i / Int(key_len)) * Int(key_len) + i % Int(key_len)] = fractionated[i]
        for p in range(key_len):
            let col = order[p]
            for row in range(rows):
                let cell = table[row * Int(key_len) + col]
                if cell != 95:
                    result.append(UInt8(cell))
    else:
        let rows = (Int(text_len) + Int(key_len) - 1) / Int(key_len)
        var table = List[Int64](length=512 * 16, fill=95)
        var source = 0
        for p in range(key_len):
            let col = order[p]
            for row in range(rows):
                if source < Int(text_len):
                    table[row * Int(key_len) + col] = input[3 + source]
                    source += 1
        var fractionated = List[Int64](capacity=512)
        for row in range(rows):
            for col in range(key_len):
                let cell = table[row * Int(key_len) + col]
                if cell != 95:
                    fractionated.append(cell)
        for i in range(0, len(fractionated), 2):
            let row = label_index(fractionated[i])
            let col = label_index(fractionated[i + 1])
            if row < 0 or col < 0:
                return -1
            let square: List[Int64] = [78,65,49,67,51,72,56,84,66,50,79,77,69,53,87,82,80,68,52,70,54,71,55,73,57,74,48,75,76,81,83,85,86,88,89,90]
            result.append(UInt8(square[row * 6 + col]))
    if capacity < c_size_t(len(result)) or (len(result) > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    for i in range(len(result)):
        output[i] = result[i]
    return Int64(len(result))
