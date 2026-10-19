from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn key_sort_compare(left: List[Int64], right: List[Int64], keys: List[Int64], key_count: Int, order: Int64) -> Int:
    for key in range(key_count):
        let column = Int(keys[key] - 1)
        if left[column] < right[column]:
            if order == 1: return -1
            return 1
        if left[column] > right[column]:
            if order == 1: return 1
            return -1
    return 0

fn key_sort_write(output: UnsafePointer[UInt8, MutAnyOrigin], position: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[position + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("array_keys_sort")
fn array_keys_sort(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 263:
        return -1
    let count = values[0]
    let raw_key_count = values[1]
    let order = values[2]
    if count < 1 or count > 64 or raw_key_count < 1 or raw_key_count > 4 or (order != 0 and order != 1): return -1
    let key_count = Int(raw_key_count)
    if length != c_size_t(3 + key_count + 4 * count): return -1
    var keys = List[Int64](capacity=4)
    for i in range(key_count):
        let key = values[3 + i]
        if key < 1 or key > 4: return -1
        for j in range(i):
            if keys[j] == key: return -1
        keys.append(key)
    var rows = List[Int64](capacity=256)
    let row_start = 3 + key_count
    for i in range(Int(4 * count)):
        let value = values[row_start + i]
        if value < -1000 or value > 1000: return -1
        rows.append(value)
    for i in range(Int(count)):
        for j in range(i + 1, Int(count)):
            var left = List[Int64](capacity=4)
            var right = List[Int64](capacity=4)
            for col in range(4):
                left.append(rows[i * 4 + col])
                right.append(rows[j * 4 + col])
            if key_sort_compare(left, right, keys, key_count, 1) == 0: return -1
    let bytes = Int(count) * 32
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(1, Int(count)):
        var temp = List[Int64](capacity=4)
        for col in range(4): temp.append(rows[i * 4 + col])
        var position = i
        while position > 0:
            var previous = List[Int64](capacity=4)
            for col in range(4): previous.append(rows[(position - 1) * 4 + col])
            if key_sort_compare(previous, temp, keys, key_count, order) <= 0: break
            for col in range(4): rows[position * 4 + col] = rows[(position - 1) * 4 + col]
            position -= 1
        for col in range(4): rows[position * 4 + col] = temp[col]
    for i in range(Int(4 * count)): key_sort_write(output, 8 * i, rows[i])
    return Int64(bytes)
