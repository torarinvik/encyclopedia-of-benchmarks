from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for b in range(8): output[offset + b] = UInt8((bits >> (8 * b)) & 255)

@export("order_preserving_huffman_greedy_trace")
fn order_preserving_huffman_greedy_trace(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 10: return -1
    let values = input[0:length]
    let raw_n = values[0]
    if raw_n < 2 or raw_n > 8 or length != c_size_t(raw_n + 1): return -1
    let n = Int(raw_n)
    var weights = InlineArray[Int64, 15]()
    var left = InlineArray[Int, 15]()
    var right = InlineArray[Int, 15]()
    var active = InlineArray[Int, 8]()
    for i in range(15): left[i] = -1; right[i] = -1
    var total: Int64 = 0
    for i in range(n):
        let w = values[i + 1]
        if w < 1 or w > 15: return -1
        weights[i] = w
        total += w
        active[i] = i
    if total > 120: return -1
    var count = n
    var next_node = n
    while count > 1:
        var pair = 0
        var best = weights[active[0]] + weights[active[1]]
        for i in range(1, count - 1):
            let candidate = weights[active[i]] + weights[active[i + 1]]
            if candidate < best:
                pair = i
                best = candidate
        let a = active[pair]
        let b = active[pair + 1]
        weights[next_node] = best
        left[next_node] = a
        right[next_node] = b
        var i = pair
        while i + 2 < count:
            active[i] = active[i + 2]
            i += 1
        count -= 2
        i = count
        while i > pair:
            active[i] = active[i - 1]
            i -= 1
        active[pair] = next_node
        count += 1
        next_node += 1
    var depths = InlineArray[Int64, 8]()
    var node_stack = InlineArray[Int, 16]()
    var depth_stack = InlineArray[Int64, 16]()
    var top = 1
    node_stack[0] = active[0]
    depth_stack[0] = 0
    while top > 0:
        top -= 1
        let node = node_stack[top]
        let depth = depth_stack[top]
        if node < n:
            depths[node] = depth
        else:
            node_stack[top] = left[node]
            depth_stack[top] = depth + 1
            top += 1
            node_stack[top] = right[node]
            depth_stack[top] = depth + 1
            top += 1
    var words = InlineArray[Int64, 10]()
    words[0] = raw_n
    for i in range(n):
        words[1] += values[i + 1] * depths[i]
        words[i + 2] = depths[i]
    let needed = 8 * (n + 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    for i in range(n + 2): store_i64(output, 8 * i, words[i])
    Int64(needed)
