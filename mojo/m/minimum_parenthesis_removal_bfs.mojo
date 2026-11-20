from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mpb_popcount(value0: Int) -> Int:
    var value = value0
    var count = 0
    while value != 0:
        count += value & 1
        value >>= 1
    return count

fn mpb_balanced(text: InlineArray[UInt8, 16], length: Int) -> Bool:
    var depth = 0
    for i in range(length):
        if text[i] == UInt8(40): depth += 1
        elif text[i] == UInt8(41):
            depth -= 1
            if depth < 0: return False
    return depth == 0

fn mpb_key_less(key: InlineArray[UInt8, 16], key_len: Int,
                rows: InlineArray[UInt8, 4096], row: Int, row_len: Int) -> Bool:
    let common = min(key_len, row_len)
    for i in range(common):
        let a = key[i]
        let b = rows[row * 16 + i]
        if a != b: return a < b
    return key_len < row_len

@export("minimum_parenthesis_removal_bfs")
fn minimum_parenthesis_removal_bfs(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(1) or length > c_size_t(17): return -1
    let n_arg = input[0]
    if n_arg < 0 or n_arg > 16 or length != c_size_t(n_arg + 1): return -1
    let n = Int(n_arg)
    var text = InlineArray[UInt8, 16]()
    var positions = InlineArray[Int32, 8]()
    var paren_count = 0
    for i in range(n):
        let value = input[i + 1]
        if value == 40 or value == 41:
            if paren_count == 8: return -1
            positions[paren_count] = Int32(i)
            paren_count += 1
        elif value < 97 or value > 122:
            return -1
        text[i] = UInt8(value)

    var rows = InlineArray[UInt8, 4096]()
    var sizes = InlineArray[UInt8, 256]()
    var count = 0
    let states = 1 << paren_count
    for deletions in range(paren_count + 1):
        for mask in range(states):
            if mpb_popcount(mask) != deletions: continue
            var candidate = InlineArray[UInt8, 16]()
            var used = 0
            var ordinal = 0
            for i in range(n):
                let at_paren = ordinal < paren_count and Int(positions[ordinal]) == i
                let remove = at_paren and (mask & (1 << ordinal)) != 0
                if at_paren: ordinal += 1
                if not remove:
                    candidate[used] = text[i]
                    used += 1
            if not mpb_balanced(candidate, used): continue
            var duplicate = False
            for r in range(count):
                if Int(sizes[r]) != used: continue
                var same = True
                for j in range(used):
                    if rows[r * 16 + j] != candidate[j]: same = False
                if same: duplicate = True
            if not duplicate:
                for j in range(used): rows[count * 16 + j] = candidate[j]
                sizes[count] = UInt8(used)
                count += 1
        if count != 0: break
    if count == 0:
        sizes[0] = UInt8(0)
        count = 1

    for i in range(1, count):
        var key = InlineArray[UInt8, 16]()
        let key_len = Int(sizes[i])
        for j in range(key_len): key[j] = rows[i * 16 + j]
        var row = i
        while row > 0 and mpb_key_less(key, key_len, rows, row - 1, Int(sizes[row - 1])):
            for j in range(Int(sizes[row - 1])):
                rows[row * 16 + j] = rows[(row - 1) * 16 + j]
            sizes[row] = sizes[row - 1]
            row -= 1
        for j in range(key_len): rows[row * 16 + j] = key[j]
        sizes[row] = UInt8(key_len)

    var needed = 2
    for r in range(count): needed += 1 + Int(sizes[r])
    if needed > 4354: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    output[0] = UInt8(count & 255)
    output[1] = UInt8((count >> 8) & 255)
    var pos = 2
    for r in range(count):
        let row_len = Int(sizes[r])
        output[pos] = UInt8(row_len)
        pos += 1
        for j in range(row_len):
            output[pos] = rows[r * 16 + j]
            pos += 1
    return Int64(pos)
