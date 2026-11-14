# Independent bounded frequent-itemset backtracking; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("frequent_itemset_backtrack")
fn frequent_itemset_backtrack(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 19: return -1
    let nv = input[0]
    let rv = input[1]
    let minimum = input[2]
    if nv < 1 or nv > 8 or rv < 1 or rv > 16 or minimum < 1 or minimum > rv or length != c_size_t(3+rv): return -1
    let n = Int(nv)
    let rows = Int(rv)
    var transactions = List[Int64](capacity=rows)
    for i in range(rows):
        let mask = input[3+i]
        if mask < 0 or mask >= (Int64(1) << n): return -1
        transactions.append(mask)
    var rowsets = List[Int](capacity=n+1)
    var prefixes = List[Int64](capacity=n+1)
    var next_items = List[Int](capacity=n+1)
    for _ in range(n+1):
        rowsets.append(0)
        prefixes.append(0)
        next_items.append(0)
    rowsets[0] = (1 << rows)-1
    var depth = 0
    var words = List[Int64](capacity=511)
    words.append(0)
    while depth >= 0:
        if next_items[depth] >= n:
            depth -= 1
            continue
        let item = next_items[depth]
        next_items[depth] += 1
        let bit = Int64(1) << item
        var projected = 0
        var support = Int64(0)
        for row in range(rows):
            if (rowsets[depth] & (1 << row)) != 0 and (transactions[row] & bit) != 0:
                projected |= 1 << row
                support += 1
        if support < minimum: continue
        let mask = prefixes[depth] | bit
        words.append(mask)
        words.append(support)
        depth += 1
        rowsets[depth] = projected
        prefixes[depth] = mask
        next_items[depth] = item+1
    words[0] = Int64((len(words)-1) // 2)
    let bytes = 8*len(words)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(words)):
        for byte in range(8): output[8*i+byte] = UInt8((words[i] >> (8*byte)) & 255)
    return Int64(bytes)
