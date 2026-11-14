# Bounded McCat bubble-sort and first-pivot quicksort profiles.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mccat_quick(head: Int, mut nodes: List[Int64], mut links: List[Int]) -> Int:
    if head < 0: return -1
    let pivot = nodes[head]
    var lower = -1
    var upper = -1
    var current = links[head]
    while current >= 0:
        let value = nodes[current]
        let following = links[current]
        let new_node = len(nodes)
        nodes.append(value)
        if value < pivot:
            links.append(lower)
            lower = new_node
        else:
            links.append(upper)
            upper = new_node
        current = following
    let sorted_upper = mccat_quick(upper, nodes, links)
    let sorted_lower = mccat_quick(lower, nodes, links)
    let pivot_node = len(nodes)
    nodes.append(pivot)
    links.append(sorted_upper)
    if sorted_lower < 0: return pivot_node
    var tail = sorted_lower
    while links[tail] >= 0: tail = links[tail]
    links[tail] = pivot_node
    return sorted_lower

@export("mccat_qbsort")
fn mccat_qbsort(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 34: return -1
    let mode = input[0]
    let nv = input[1]
    if (mode != 0 and mode != 1) or nv < 1 or nv > 32 or length != c_size_t(nv+2): return -1
    let n = Int(nv)
    var original = List[Int64](capacity=n)
    var values = List[Int64](capacity=n)
    for i in range(n):
        let value = input[2+i]
        if value < -2147483648 or value > 2147483647: return -1
        original.append(value)
        values.append(value)
    for _ in range(1000):
        for i in range(n): values[i] = original[i]
        if mode == 0:
            var end = n-1
            while end > 0:
                for i in range(end):
                    if values[i+1] < values[i]:
                        let temporary = values[i]
                        values[i] = values[i+1]
                        values[i+1] = temporary
                end -= 1
        else:
            var nodes = List[Int64](capacity=n)
            var links = List[Int](capacity=n)
            for i in range(n):
                nodes.append(values[i])
                links.append(i+1 if i+1 < n else -1)
            var current = mccat_quick(0, nodes, links)
            var position = 0
            while current >= 0:
                values[position] = nodes[current]
                current = links[current]
                position += 1
    let bytes = 4*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n):
        for byte in range(4): output[4*i+byte] = UInt8((values[i] >> (8*byte)) & 255)
    return Int64(bytes)
