from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn duplicate_heap_sift(inout a: InlineArray[Int32, 100000], root_input: Int64, end: Int64):
    var root = root_input
    while 2 * root + 1 < end:
        var child = 2 * root + 1
        if child + 1 < end and a[child] < a[child + 1]: child += 1
        if a[root] >= a[child]: return
        let temp = a[root]
        a[root] = a[child]
        a[child] = temp
        root = child

@export("find_all_duplicates_in_array")
fn find_all_duplicates_in_array(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if length > 100000 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    if length == 0: return 0
    var sorted = InlineArray[Int32, 100000](0)
    for i in range(length):
        if values[i] < 1 or values[i] > length: return -1
        sorted[i] = Int32(values[i])
    var start = Int64(length) / 2
    while start > 0:
        start -= 1
        duplicate_heap_sift(sorted, start, length)
    var end = Int64(length)
    while end > 1:
        end -= 1
        let temp = sorted[0]
        sorted[0] = sorted[end]
        sorted[end] = temp
        duplicate_heap_sift(sorted, 0, end)
    var count: Int64 = 0
    var i: Int64 = 0
    while i < length:
        var j = i + 1
        while j < length and sorted[j] == sorted[i]: j += 1
        let frequency = j - i
        if frequency > 2: return -1
        if frequency == 2: count += 1
        i = j
    let bytes = count * 4
    if output_capacity < bytes or (bytes > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var out: Int64 = 0
    i = 0
    while i < length:
        var j = i + 1
        while j < length and sorted[j] == sorted[i]: j += 1
        if j - i == 2:
            let bits = UInt32(sorted[i])
            for b in range(4): output[out * 4 + b] = UInt8((bits >> (8 * b)) & 255)
            out += 1
        i = j
    return count
