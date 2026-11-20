from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 64
const MAX_Q = 64
const MAX_INPUT_LENGTH = 195

@export("offline_range_paint_successor_dsu")
fn offline_range_paint_successor_dsu(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH: return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + 3 * q): return -1
    var left = InlineArray[Int64, 64](fill=0)
    var right = InlineArray[Int64, 64](fill=0)
    var color = InlineArray[Int64, 64](fill=0)
    for j in range(q):
        left[j] = input[2 + 3 * j]
        right[j] = input[3 + 3 * j]
        color[j] = input[4 + 3 * j]
        if left[j] < 0 or left[j] > right[j] or right[j] >= n_value or color[j] < -1000 or color[j] > 1000: return -1
    var parent = InlineArray[Int64, 65](fill=0)
    var final_color = InlineArray[Int64, 64](fill=0)
    for i in range(n + 1): parent[i] = Int64(i)
    for reverse_index in range(q):
        let operation = q - reverse_index - 1
        var cell = Int(left[operation])
        var root = cell
        while Int(parent[root]) != root: root = Int(parent[root])
        while Int(parent[cell]) != cell:
            let next = Int(parent[cell])
            parent[cell] = Int64(root)
            cell = next
        while cell <= Int(right[operation]):
            final_color[cell] = color[operation]
            var next_cell = cell + 1
            root = next_cell
            while Int(parent[root]) != root: root = Int(parent[root])
            while Int(parent[next_cell]) != next_cell:
                let following = Int(parent[next_cell])
                parent[next_cell] = Int64(root)
                next_cell = following
            parent[cell] = Int64(root)
            cell = root
    var checksum: Int64 = 0
    for i in range(n): checksum += Int64(i + 1) * (final_color[i] + 1001)
    return checksum
