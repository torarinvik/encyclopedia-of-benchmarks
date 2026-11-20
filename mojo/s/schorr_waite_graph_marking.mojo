from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("schorr_waite_graph_marking")
fn schorr_waite_graph_marking(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 66:
        return -1

    let node_count_value = input[0]
    let root = input[1]
    if node_count_value < 1 or node_count_value > 32:
        return -1
    let node_count = Int(node_count_value)
    if length != c_size_t(2 + 2 * node_count) or root < 0 or root >= node_count_value:
        return -1

    var left = InlineArray[Int64, 32](fill=0)
    var right = InlineArray[Int64, 32](fill=0)
    var marked = InlineArray[Bool, 32](fill=False)
    var phase = InlineArray[Bool, 32](fill=False)
    for node in range(node_count):
        let left_child = input[2 + 2 * node]
        let right_child = input[3 + 2 * node]
        if left_child < -1 or left_child >= node_count_value or right_child < -1 or right_child >= node_count_value:
            return -1
        left[node] = left_child
        right[node] = right_child

    var parent: Int64 = -1
    var current = root
    var temporary: Int64 = 0
    while parent != -1 or (current != -1 and not marked[Int(current)]):
        if current == -1 or marked[Int(current)]:
            let frame = Int(parent)
            if phase[frame]:
                temporary = current
                current = parent
                parent = right[frame]
                right[frame] = temporary
            else:
                temporary = current
                current = right[frame]
                right[frame] = left[frame]
                left[frame] = temporary
                phase[frame] = True
        else:
            temporary = parent
            parent = current
            current = left[Int(parent)]
            left[Int(parent)] = temporary
            marked[Int(parent)] = True
            phase[Int(parent)] = False

    var reachable: Int64 = 0
    for node in range(node_count):
        if marked[node]:
            reachable |= Int64(1) << node
    return reachable
