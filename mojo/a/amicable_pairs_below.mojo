from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn amicable_write_u32(output: UnsafePointer[UInt8, MutAnyOrigin], mut pos: Int, value: Int64):
    let bits = UInt32(value)
    for b in range(4):
        output[pos] = UInt8((bits >> (8 * b)) & 255)
        pos += 1

@export("amicable_pairs_below")
fn amicable_pairs_below(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1 or values[0] < 1 or values[0] > 8000:
        return -1
    let limit = Int(values[0])
    var sums = List[Int64](length=limit, fill=0)
    for d in range(1, limit):
        var multiple = 2 * d
        while multiple < limit:
            sums[multiple] += d
            multiple += d
    var pairs = List[Int64](capacity=4000)
    for small in range(2, limit):
        let large = sums[small]
        if large > Int64(small) and large < Int64(limit) and sums[Int(large)] == Int64(small):
            pairs.append(Int64(small))
            pairs.append(large)
    let pair_count = len(pairs) / 2
    if capacity < c_size_t(pair_count * 8) or (pair_count > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    var pos = 0
    for i in range(pair_count):
        amicable_write_u32(output, pos, pairs[2 * i]); pos += 4
        amicable_write_u32(output, pos, pairs[2 * i + 1]); pos += 4
    return Int64(pair_count)
