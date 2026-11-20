from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("segment_tree_max_right")
fn segment_tree_max_right(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 55: return -1
    let nr = input[0]
    let qr = input[1]
    if nr < 0 or nr > 16 or qr < 0 or qr > 12: return -1
    let n = Int(nr)
    let operations = Int(qr)
    if length != c_size_t(2 + n + 3 * operations): return -1

    var tree = InlineArray[Int64, 64](fill=0)
    var size = 1
    while size < n: size *= 2
    for i in range(n):
        let value = input[2 + i]
        if value < 0 or value > 1000: return -1
        tree[size + i] = value
    var node = size
    while node > 1:
        node -= 1
        tree[node] = tree[2 * node] + tree[2 * node + 1]

    var query_index = 0
    var result: Int64 = 0
    var cursor = 2 + n
    for operation in range(operations):
        let opcode = input[cursor]
        let first = input[cursor + 1]
        let second = input[cursor + 2]
        cursor += 3
        if opcode == 0:
            if first < 0 or first >= nr or second < 0 or second > 1000: return -1
            node = size + Int(first)
            tree[node] = second
            while node > 1:
                node /= 2
                tree[node] = tree[2 * node] + tree[2 * node + 1]
        elif opcode == 1:
            if first < 0 or first > nr or second < 0 or second > 16000: return -1
            let left = Int(first)
            var boundary = n
            if left < n:
                var position = left + size
                var accumulated: Int64 = 0
                var done = False
                while not done:
                    while (position & 1) == 0: position /= 2
                    if accumulated + tree[position] > second:
                        while position < size:
                            position *= 2
                            if accumulated + tree[position] <= second:
                                accumulated += tree[position]
                                position += 1
                        boundary = position - size
                        if boundary > n: boundary = n
                        done = True
                    else:
                        accumulated += tree[position]
                        position += 1
                        if (position & (position - 1)) == 0: done = True
            result |= Int64(boundary) << (5 * query_index)
            query_index += 1
        else:
            return -1
    return result
