# Independent bounded conditional-database reduction; see package rights note.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("frequent_itemset_conditional_db_reduction")
fn frequent_itemset_conditional_db_reduction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
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
    var selected = List[Int64](capacity=rows)
    var support = List[Int64](capacity=n)
    for _ in range(n): support.append(0)
    for row in range(rows):
        let mask = input[5+row]
        if mask < 0 or mask >= (Int64(1) << n): return -1
        if (mask & prefix) == prefix:
            selected.append(mask)
            for item in range(Int(tail+1),n):
                if (mask & (Int64(1) << item)) != 0: support[item] += 1
    if Int64(len(selected)) < minimum: return -1
    var keep = Int64(0)
    if tail >= 0: keep = Int64(1) << Int(tail)
    for item in range(Int(tail+1),n):
        if support[item] >= minimum: keep |= Int64(1) << item
    var masks = List[Int64](capacity=rows)
    var counts = List[Int64](capacity=rows)
    for row in range(len(selected)):
        let reduced = selected[row] & keep
        var i = 0
        while i < len(masks) and masks[i] != reduced: i += 1
        if i == len(masks):
            masks.append(reduced)
            counts.append(0)
        counts[i] += 1
    for i in range(1,len(masks)):
        let mask = masks[i]
        let count = counts[i]
        var j = i
        while j > 0 and masks[j-1] > mask:
            masks[j] = masks[j-1]
            counts[j] = counts[j-1]
            j -= 1
        masks[j] = mask
        counts[j] = count
    let bytes = 8*(1+2*len(masks))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var words = List[Int64](capacity=1+2*len(masks))
    words.append(Int64(len(masks)))
    for i in range(len(masks)):
        words.append(masks[i])
        words.append(counts[i])
    for i in range(len(words)):
        for byte in range(8): output[8*i+byte] = UInt8((words[i] >> (8*byte)) & 255)
    return Int64(bytes)
