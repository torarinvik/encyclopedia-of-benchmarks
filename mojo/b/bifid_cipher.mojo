from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn fixed_square_index(value: Int64, merge_j: Bool) -> Int:
    var ch = value
    if ch >= 97 and ch <= 122: ch -= 32
    if ch < 65 or ch > 90: return -1
    var index = Int(ch - 65)
    if index == 9:
        if not merge_j: return -1
        index = 8
    elif index > 9: index -= 1
    return index

fn square_letter(index: Int) -> UInt8:
    return UInt8(97 + index + (1 if index >= 9 else 0))

@export("bifid_cipher")
fn bifid_cipher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258: return -1
    let mode = input[0]; let tv = input[1]
    if (mode != 0 and mode != 1) or tv < 0 or tv > 256 or length != c_size_t(tv + 2): return -1
    let n = Int(tv)
    var rows = List[Int](capacity=n); var cols = List[Int](capacity=n); var result = List[UInt8](capacity=n)
    if mode == 0:
        for i in range(n):
            let ch = input[2 + i]
            if ch == 32: continue
            let index = fixed_square_index(ch, True)
            if index < 0: return -1
            rows.append(index // 5 + 1); cols.append(index % 5 + 1)
        var coords = List[Int](capacity=2 * len(rows))
        for v in rows: coords.append(v)
        for v in cols: coords.append(v)
        for i in range(len(rows)):
            result.append(square_letter((coords[2 * i] - 1) * 5 + coords[2 * i + 1] - 1))
    else:
        var coords = List[Int](capacity=2 * n)
        for i in range(n):
            let index = fixed_square_index(input[2 + i], False)
            if index < 0: return -1
            coords.append(index // 5 + 1); coords.append(index % 5 + 1)
        for i in range(n):
            result.append(square_letter((coords[i] - 1) * 5 + coords[n + i] - 1))
    if capacity < c_size_t(len(result)) or (len(result) > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for i in range(len(result)): output[i] = result[i]
    return Int64(len(result))
