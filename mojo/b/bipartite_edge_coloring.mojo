"""Minimum edge coloring of a bounded bipartite multigraph."""
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn augment(left: Int, side: Int, multiplicity: List[Int], mut seen: List[Bool],
           mut match_right: List[Int]) -> Bool:
    for right in range(side):
        let index = left * 5 + right
        if multiplicity[index] == 0 or seen[right]: continue
        seen[right] = True
        let mate = match_right[right]
        if mate < 0 or augment(mate, side, multiplicity, mut seen, mut match_right):
            match_right[right] = left
            return True
    return False

fn store_u64_le(value: UInt64, mut output: List[UInt8], offset: Int):
    for byte in range(8):
        output[offset + byte] = UInt8((value >> (byte * 8)) & 0xff)

@export("bipartite_edge_coloring")
fn bipartite_edge_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 23: return -1
    let left_value = input[0]
    let right_value = input[1]
    let edge_value = input[2]
    if left_value < 1 or left_value > 5 or right_value < 1 or right_value > 5 or
        edge_value < 1 or edge_value > 10: return -1
    let left_count = Int(left_value)
    let right_count = Int(right_value)
    let edge_count = Int(edge_value)
    if length != c_size_t(3 + 2 * edge_count): return -1

    var multiplicity = List[Int](capacity=25)
    var original_remaining = List[Int](capacity=25)
    for _ in range(25):
        multiplicity.append(0)
        original_remaining.append(0)
    var left_degree = List[Int](capacity=5)
    var right_degree = List[Int](capacity=5)
    for _ in range(5):
        left_degree.append(0)
        right_degree.append(0)
    var edge_left = List[Int](capacity=10)
    var edge_right = List[Int](capacity=10)
    var colors = List[Int](capacity=10)
    for _ in range(10):
        edge_left.append(0)
        edge_right.append(0)
        colors.append(-1)

    for edge in range(edge_count):
        let left = input[3 + 2 * edge]
        let right = input[4 + 2 * edge]
        if left < 0 or left >= left_value or right < 0 or right >= right_value: return -1
        let u = Int(left)
        let v = Int(right)
        edge_left[edge] = u
        edge_right[edge] = v
        let index = u * 5 + v
        multiplicity[index] += 1
        original_remaining[index] += 1
        left_degree[u] += 1
        right_degree[v] += 1

    let side = max(left_count, right_count)
    var maximum_degree = 0
    for vertex in range(side):
        maximum_degree = max(maximum_degree, max(left_degree[vertex], right_degree[vertex]))
    while True:
        var left = 0
        while left < side and left_degree[left] == maximum_degree: left += 1
        if left == side: break
        var right = 0
        while right < side and right_degree[right] == maximum_degree: right += 1
        if right == side: return -1
        multiplicity[left * 5 + right] += 1
        left_degree[left] += 1
        right_degree[right] += 1

    for color in range(maximum_degree):
        var match_right = List[Int](capacity=5)
        for _ in range(5): match_right.append(-1)
        for left in range(side):
            var seen = List[Bool](capacity=5)
            for _ in range(5): seen.append(False)
            if not augment(left, side, multiplicity, mut seen, mut match_right): return -1
        for right in range(side):
            let left = match_right[right]
            if left < 0: return -1
            let index = left * 5 + right
            if original_remaining[index] > 0:
                var edge = 0
                while edge < edge_count and
                    (colors[edge] >= 0 or edge_left[edge] != left or edge_right[edge] != right):
                    edge += 1
                if edge == edge_count: return -1
                colors[edge] = color
                original_remaining[index] -= 1
            multiplicity[index] -= 1

    let bytes = 8 * (edge_count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var staged = List[UInt8](capacity=88)
    for _ in range(88): staged.append(0)
    store_u64_le(UInt64(maximum_degree), mut staged, 0)
    for edge in range(edge_count):
        store_u64_le(UInt64(colors[edge]), mut staged, 8 * (edge + 1))
    for byte in range(bytes): output[byte] = staged[byte]
    return Int64(bytes)
