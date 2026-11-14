# Independent bounded occurrence-delivery profile; see package rights note.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("frequent_itemset_delivery")
fn frequent_itemset_delivery(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                             output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 69: return -1
    let nv = input[0]
    let rv = input[1]
    let minimum = input[2]
    let tail = input[3]
    let prefix = input[4]
    if nv < 1 or nv > 8 or rv < 1 or rv > 64 or minimum < 1 or minimum > rv or length != c_size_t(5+rv): return -1
    if tail < -1 or tail >= nv or prefix < 0 or prefix >= (Int64(1) << Int(nv)): return -1
    if tail == -1 and prefix != 0: return -1
    if tail >= 0 and (((prefix >> Int(tail)) & 1) == 0 or (prefix >> Int(tail+1)) != 0): return -1
    let n = Int(nv)
    let rows = Int(rv)
    var occurrences = List[UInt64](capacity=n)
    var supports = List[Int64](capacity=n)
    for _ in range(n):
        occurrences.append(0)
        supports.append(0)
    for row in range(rows):
        let mask = input[5+row]
        if mask < 0 or mask >= (Int64(1) << n): return -1
        if (mask & prefix) == prefix:
            for item in range(Int(tail+1),n):
                if (mask & (Int64(1) << item)) != 0:
                    occurrences[item] |= UInt64(1) << row
                    supports[item] += 1
    var words = List[UInt64](capacity=25)
    words.append(0)
    var records = UInt64(0)
    for item in range(Int(tail+1),n):
        if supports[item] >= minimum:
            records += 1
            words.append(UInt64(item))
            words.append(occurrences[item])
            words.append(UInt64(supports[item]))
    words[0] = records
    let bytes = 8*len(words)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(words)):
        for byte in range(8): output[8*i+byte] = UInt8((words[i] >> (8*byte)) & UInt64(255))
    return Int64(bytes)
