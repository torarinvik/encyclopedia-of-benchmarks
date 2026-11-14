# Bounded index-linked traversal and fractional list growth.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("llubenchmark_list_traversal_growth")
fn llubenchmark_list_traversal_growth(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    let lists = input[0]
    let initial = input[1]
    let iterations = input[2]
    if lists < 1 or lists > 4 or initial < 1 or initial > 4 or iterations < 0 or iterations > 16: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    let count_lists = Int(lists)
    var next = List[Int](capacity=36)
    var counts = List[Int64](capacity=36)
    var head = List[Int](capacity=count_lists)
    var tail = List[Int](capacity=count_lists)
    for _ in range(count_lists):
        head.append(-1)
        tail.append(-1)
    for _ in range(Int(initial)):
        for list in range(count_lists):
            let node = len(next)
            next.append(head[list])
            counts.append(0)
            head[list] = node
            if tail[list] == -1: tail[list] = node
    var accumulated = Int64(0)
    var growth = 0
    for _ in range(Int(iterations)):
        for list in range(count_lists):
            var node = head[list]
            while node != -1:
                accumulated += counts[node]
                counts[node] += 1
                node = next[node]
        growth += 333
        if growth >= 1000:
            growth -= 1000
            for list in range(count_lists):
                let node = len(next)
                next.append(-1)
                counts.append(Int64(list+1))
                next[tail[list]] = node
                tail[list] = node
    let allocated = Int64(len(next))
    for byte in range(8):
        output[byte] = UInt8((accumulated >> (8*byte)) & 255)
        output[8+byte] = UInt8((allocated >> (8*byte)) & 255)
    return 2
