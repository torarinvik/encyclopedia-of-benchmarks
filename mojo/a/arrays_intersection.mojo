from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn arrays_hash_slot(value: Int64) -> Int:
    var remainder = value % 257
    if remainder < 0: remainder += 257
    return Int(remainder)

fn arrays_write_i32(output: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64):
    let bits = UInt32(value)
    for b in range(4): output[pos + b] = UInt8((bits >> UInt(8 * b)) & 255)

@export("arrays_intersection")
fn arrays_intersection(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 195: return -1
    var starts = List[Int](length=3, fill=0)
    var sizes = List[Int](length=3, fill=0)
    var pos = 0
    for array in range(3):
        if pos >= Int(length) or input[pos] < 0 or input[pos] > 64: return -1
        let size = Int(input[pos])
        pos += 1
        if size > Int(length) - pos: return -1
        starts[array] = pos
        sizes[array] = size
        for i in range(size):
            if input[pos + i] < -2147483648 or input[pos + i] > 2147483647: return -1
        pos += size
    if pos != Int(length): return -1
    var keys = List[Int64](length=257, fill=0)
    var counts = List[Int](length=257, fill=0)
    var occupied = List[Int](length=257, fill=0)
    var order = List[Int](capacity=192)
    for array in range(3):
        for i in range(sizes[array]):
            let value = input[starts[array] + i]
            var slot = arrays_hash_slot(value)
            while occupied[slot] != 0 and keys[slot] != value: slot = (slot + 1) % 257
            if occupied[slot] == 0:
                occupied[slot] = 1
                keys[slot] = value
                counts[slot] = 0
                order.append(slot)
            counts[slot] += 1
    var matches = 0
    for i in range(len(order)):
        if counts[order[i]] == 3: matches += 1
    if (matches > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()) or capacity < c_size_t(matches * 4): return -2
    var written = 0
    for i in range(len(order)):
        let slot = order[i]
        if counts[slot] == 3:
            arrays_write_i32(output, written * 4, keys[slot])
            written += 1
    return Int64(written)
