from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer


@export("move_to_root_bst_access_trace")
fn move_to_root_bst_access_trace(values: UnsafePointer[Int64, ImmutAnyOrigin],
                                 length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 51:
        return -1
    let initial_count = values[0]
    if initial_count < 0 or initial_count > 16:
        return -1
    let query_count_index = 1 + Int(initial_count)
    if length < c_size_t(query_count_index + 1):
        return -1
    let access_count = values[query_count_index]
    if access_count < 0 or access_count > 32 or length != c_size_t(query_count_index + 1 + Int(access_count)):
        return -1

    var keys = InlineArray[Int64, 16]()
    var left = InlineArray[Int32, 16]()
    var right = InlineArray[Int32, 16]()
    var parent = InlineArray[Int32, 16]()
    for index in range(16):
        left[index] = -1
        right[index] = -1
        parent[index] = -1
    for index in range(Int(initial_count)):
        let key = values[1 + index]
        if key < -100 or key > 100:
            return -1
        for earlier in range(index):
            if values[1 + earlier] == key:
                return -1
        keys[index] = key
    for query in range(Int(access_count)):
        let key = values[query_count_index + 1 + query]
        if key < -100 or key > 100:
            return -1

    var root: Int32 = -1
    for index in range(Int(initial_count)):
        var node = Int32(index)
        if root == -1:
            root = node
            continue
        var current = root
        while True:
            if keys[Int(node)] < keys[Int(current)]:
                if left[Int(current)] == -1:
                    left[Int(current)] = node
                    parent[Int(node)] = current
                    break
                current = left[Int(current)]
            else:
                if right[Int(current)] == -1:
                    right[Int(current)] = node
                    parent[Int(node)] = current
                    break
                current = right[Int(current)]

    var result: Int64 = 0
    for query_number in range(1, Int(access_count) + 1):
        let key = values[query_count_index + query_number]
        var node = root
        var comparisons: Int64 = 0
        while node != -1:
            comparisons += 1
            if key == keys[Int(node)]:
                break
            if key < keys[Int(node)]:
                node = left[Int(node)]
            else:
                node = right[Int(node)]
        while node != -1 and parent[Int(node)] != -1:
            let old_parent = parent[Int(node)]
            let grandparent = parent[Int(old_parent)]
            if left[Int(old_parent)] == node:
                let middle = right[Int(node)]
                right[Int(node)] = old_parent
                left[Int(old_parent)] = middle
                if middle != -1:
                    parent[Int(middle)] = old_parent
            else:
                let middle = left[Int(node)]
                left[Int(node)] = old_parent
                right[Int(old_parent)] = middle
                if middle != -1:
                    parent[Int(middle)] = old_parent
            parent[Int(old_parent)] = node
            parent[Int(node)] = grandparent
            if grandparent == -1:
                root = node
            elif left[Int(grandparent)] == old_parent:
                left[Int(grandparent)] = node
            else:
                right[Int(grandparent)] = node
        result += Int64(query_number) * comparisons
    return result
