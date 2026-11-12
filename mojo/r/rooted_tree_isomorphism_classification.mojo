from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_TREES = 16
alias MAX_TREE_VERTICES = 32
alias MAX_TOTAL_VERTICES = 128
alias MAX_INPUT_LENGTH = 1 + 2 * MAX_TREES * MAX_TREE_VERTICES
alias SIGNATURE_CELLS = MAX_TOTAL_VERTICES * MAX_TREE_VERTICES

@export("rooted_tree_isomorphism_classification")
fn rooted_tree_isomorphism_classification(
    input: UnsafePointer[Int64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < c_size_t(1) or input_length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    if input[0] < 1 or input[0] > MAX_TREES:
        return -1

    let tree_count = Int(input[0])
    var position = 1
    var total_vertices = 0
    var signature_count = 0
    var signatures = InlineArray[Int, SIGNATURE_CELLS]()
    var signature_sizes = InlineArray[Int, MAX_TOTAL_VERTICES]()
    var root_types = InlineArray[Int, MAX_TREES]()
    var labels = InlineArray[Int, MAX_TREES]()
    var class_count = 0

    for tree in range(tree_count):
        if position + 2 > Int(input_length):
            return -1
        let vertex_count_value = input[position]
        let root_value = input[position + 1]
        position += 2
        if vertex_count_value < 1 or vertex_count_value > MAX_TREE_VERTICES or root_value < 0 or root_value >= vertex_count_value:
            return -1
        let vertex_count = Int(vertex_count_value)
        let root = Int(root_value)
        total_vertices += vertex_count
        if total_vertices > MAX_TOTAL_VERTICES:
            return -1
        let edge_count = vertex_count - 1
        if 2 * edge_count > Int(input_length) - position:
            return -1

        var adjacency = InlineArray[UInt32, MAX_TREE_VERTICES]()
        for _edge in range(edge_count):
            let left_value = input[position]
            let right_value = input[position + 1]
            position += 2
            if left_value < 0 or left_value >= vertex_count_value or right_value < 0 or right_value >= vertex_count_value or left_value == right_value:
                return -1
            let left = Int(left_value)
            let right = Int(right_value)
            let left_bit = UInt32(1) << right
            let right_bit = UInt32(1) << left
            if (adjacency[left] & left_bit) != UInt32(0):
                return -1
            adjacency[left] |= left_bit
            adjacency[right] |= right_bit

        var parent = InlineArray[Int, MAX_TREE_VERTICES](-1)
        var visited = InlineArray[Bool, MAX_TREE_VERTICES]()
        var order = InlineArray[Int, MAX_TREE_VERTICES]()
        var stack = InlineArray[Int, MAX_TREE_VERTICES]()
        var node_types = InlineArray[Int, MAX_TREE_VERTICES]()
        parent[root] = root
        visited[root] = True
        stack[0] = root
        var stack_size = 1
        var order_size = 0
        while stack_size > 0:
            stack_size -= 1
            let vertex = stack[stack_size]
            order[order_size] = vertex
            order_size += 1
            for neighbor in range(vertex_count):
                let bit = UInt32(1) << neighbor
                if (adjacency[vertex] & bit) == UInt32(0) or neighbor == parent[vertex]:
                    continue
                if visited[neighbor]:
                    return -1
                visited[neighbor] = True
                parent[neighbor] = vertex
                stack[stack_size] = neighbor
                stack_size += 1
        if order_size != vertex_count:
            return -1

        for reverse_index in range(order_size):
            let vertex = order[order_size - 1 - reverse_index]
            var children = InlineArray[Int, MAX_TREE_VERTICES]()
            var child_count = 0
            for candidate in range(vertex_count):
                if candidate != vertex and parent[candidate] == vertex:
                    children[child_count] = node_types[candidate]
                    child_count += 1
            for index in range(1, child_count):
                var cursor = index
                while cursor > 0 and children[cursor] < children[cursor - 1]:
                    let temporary = children[cursor]
                    children[cursor] = children[cursor - 1]
                    children[cursor - 1] = temporary
                    cursor -= 1

            var signature = 0
            while signature < signature_count:
                if signature_sizes[signature] == child_count:
                    var equal = True
                    for child in range(child_count):
                        if signatures[signature * MAX_TREE_VERTICES + child] != children[child]:
                            equal = False
                            break
                    if equal:
                        break
                signature += 1
            if signature == signature_count:
                if signature_count >= MAX_TOTAL_VERTICES:
                    return -1
                signature_sizes[signature] = child_count
                for child in range(child_count):
                    signatures[signature * MAX_TREE_VERTICES + child] = children[child]
                signature_count += 1
            node_types[vertex] = signature

        root_types[tree] = node_types[root]
        var prior = 0
        while prior < tree and root_types[prior] != root_types[tree]:
            prior += 1
        if prior < tree:
            labels[tree] = labels[prior]
        else:
            labels[tree] = class_count
            class_count += 1

    if position != Int(input_length):
        return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(tree_count):
        return -2
    for tree in range(tree_count):
        output[tree] = UInt8(labels[tree])
    return Int64(tree_count)
