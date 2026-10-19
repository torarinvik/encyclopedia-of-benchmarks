from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn association_popcount(value0: Int) -> Int:
    var value = value0
    var count = 0
    while value != 0:
        count += value & 1
        value >>= 1
    return count

fn association_store(output: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8): output[pos + b] = UInt8((bits >> UInt(8 * b)) & 255)

@export("association")
fn association(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 11: return -1
    let transactions = Int(input[0])
    let items = Int(input[1])
    if length != c_size_t(2 + transactions): return -1
    let limit = 1 << items
    for t in range(transactions):
        if input[2 + t] < 0 or input[2 + t] >= Int64(limit): return -1
    var frequent = List[Int](length=2048, fill=0)
    var masks = List[Int64](capacity=2047)
    var supports = List[Int64](capacity=2047)
    for size in range(1, items + 1):
        for mask in range(1, limit):
            if association_popcount(mask) != size: continue
            if size > 1:
                var all_subsets = True
                for bit in range(items):
                    let one = 1 << bit
                    if (mask & one) != 0 and frequent[mask ^ one] == 0: all_subsets = False
                if not all_subsets: continue
            var support: Int64 = 0
            for t in range(transactions):
                if (Int(input[2 + t]) & mask) == mask: support += 1
            if support > 0:
                frequent[mask] = 1
                masks.append(Int64(mask))
                supports.append(support)
    let bytes = len(masks) * 16
    if (bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()) or capacity < c_size_t(bytes): return -2
    for i in range(len(masks)):
        association_store(output, i * 16, masks[i])
        association_store(output, i * 16 + 8, supports[i])
    return Int64(bytes)
