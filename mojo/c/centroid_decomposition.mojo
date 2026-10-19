from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_NODES = 64
comptime MAX_EDGES = 126

@export("centroid_decomposition")
fn centroid_decomposition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 127: return -1
    let n = input[0]
    if n < 1 or n > MAX_NODES or length != 2 * n - 1: return -1
    var set_parent = InlineArray[Int64, 64](0)
    var head = InlineArray[Int64, 64](-1)
    var edge_to = InlineArray[Int64, 126](0)
    var edge_next = InlineArray[Int64, 126](-1)
    for node in range(n): set_parent[node] = node
    var edge_count: Int64 = 0
    for pos in range(1, length, 2):
        let left = input[pos]
        let right = input[pos + 1]
        if left < 0 or left >= n or right < 0 or right >= n or left == right: return -1
        var left_root = left
        while set_parent[left_root] != left_root: left_root = set_parent[left_root]
        var right_root = right
        while set_parent[right_root] != right_root: right_root = set_parent[right_root]
        if left_root == right_root: return -1
        set_parent[right_root] = left_root
        edge_to[edge_count] = right
        edge_next[edge_count] = head[left]
        head[left] = edge_count
        edge_count += 1
        edge_to[edge_count] = left
        edge_next[edge_count] = head[right]
        head[right] = edge_count
        edge_count += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < n * 4: return -2
    var removed = InlineArray[Int64, 64](0)
    var traversal_parent = InlineArray[Int64, 64](0)
    var subtree_size = InlineArray[Int64, 64](0)
    var order = InlineArray[Int64, 64](0)
    var stack = InlineArray[Int64, 64](0)
    var task_node = InlineArray[Int64, 64](0)
    var task_parent = InlineArray[Int64, 64](0)
    var decomposition_parent = InlineArray[Int64, 64](0)
    var task_count: Int64 = 1
    task_node[0] = 0
    task_parent[0] = -1
    while task_count > 0:
        task_count -= 1
        let start = task_node[task_count]
        let centroid_parent = task_parent[task_count]
        for node in range(n): traversal_parent[node] = -2
        var stack_count: Int64 = 1
        var order_count: Int64 = 0
        stack[0] = start
        traversal_parent[start] = -1
        while stack_count > 0:
            stack_count -= 1
            let node = stack[stack_count]
            order[order_count] = node
            order_count += 1
            subtree_size[node] = 1
            var edge = head[node]
            while edge >= 0:
                let neighbor = edge_to[edge]
                if neighbor != traversal_parent[node] and removed[neighbor] == 0 and traversal_parent[neighbor] == -2:
                    traversal_parent[neighbor] = node
                    stack[stack_count] = neighbor
                    stack_count += 1
                edge = edge_next[edge]
        var index = order_count
        while index > 0:
            index -= 1
            let node = order[index]
            let parent = traversal_parent[node]
            if parent >= 0: subtree_size[parent] += subtree_size[node]
        var centroid: Int64 = -1
        var smallest_largest = n + 1
        for order_index in range(order_count):
            let node = order[order_index]
            var largest = order_count - subtree_size[node]
            var edge = head[node]
            while edge >= 0:
                let neighbor = edge_to[edge]
                if traversal_parent[neighbor] == node and subtree_size[neighbor] > largest: largest = subtree_size[neighbor]
                edge = edge_next[edge]
            if largest < smallest_largest or (largest == smallest_largest and node < centroid):
                centroid = node
                smallest_largest = largest
        decomposition_parent[centroid] = centroid_parent
        removed[centroid] = 1
        var edge = head[centroid]
        while edge >= 0:
            let neighbor = edge_to[edge]
            if removed[neighbor] == 0:
                task_node[task_count] = neighbor
                task_parent[task_count] = centroid
                task_count += 1
            edge = edge_next[edge]
    var staged = InlineArray[UInt8, 256](0)
    for node in range(n):
        let bits = UInt32(4294967295) if decomposition_parent[node] < 0 else UInt32(decomposition_parent[node])
        staged[4 * node] = UInt8(bits & 255)
        staged[4 * node + 1] = UInt8((bits >> 8) & 255)
        staged[4 * node + 2] = UInt8((bits >> 16) & 255)
        staged[4 * node + 3] = UInt8((bits >> 24) & 255)
    for i in range(n * 4): output[i] = staged[i]
    return n
