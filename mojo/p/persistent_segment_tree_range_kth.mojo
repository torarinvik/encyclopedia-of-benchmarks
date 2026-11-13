from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn persistent_segment_tree_range_kth(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 131:
        return -9223372036854775808
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > 32 or q_value < 0 or q_value > 32:
        return -9223372036854775808
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + n + 3 * q):
        return -9223372036854775808

    var coordinates = InlineArray[Int64, 32]()
    for i in range(n):
        let value = input[2 + i]
        if value < -1000 or value > 1000:
            return -9223372036854775808
        coordinates[i] = value
    for i in range(1, n):
        let value = coordinates[i]
        var j = i
        while j > 0 and coordinates[j - 1] > value:
            coordinates[j] = coordinates[j - 1]
            j -= 1
        coordinates[j] = value
    var distinct = 0
    for i in range(n):
        if distinct == 0 or coordinates[i] != coordinates[distinct - 1]:
            coordinates[distinct] = coordinates[i]
            distinct += 1

    let query_offset = 2 + n
    for qi in range(q):
        let offset = query_offset + 3 * qi
        let left = input[offset]
        let right = input[offset + 1]
        let k = input[offset + 2]
        if left < 0 or right < left or right >= n_value or k < 1 or k > right - left + 1:
            return -9223372036854775808

    var left_child = InlineArray[Int32, 193]()
    var right_child = InlineArray[Int32, 193]()
    var counts = InlineArray[Int32, 193]()
    var roots = InlineArray[Int32, 33]()
    var node_count = 1
    for i in range(n):
        let value = input[2 + i]
        var low = 0
        var high = distinct
        while low < high:
            let middle = low + (high - low) // 2
            if coordinates[middle] < value:
                low = middle + 1
            else:
                high = middle
        let rank = low
        let previous_root = Int(roots[i])
        if node_count >= 193:
            return -9223372036854775808
        let new_root = node_count
        node_count += 1
        left_child[new_root] = left_child[previous_root]
        right_child[new_root] = right_child[previous_root]
        counts[new_root] = counts[previous_root] + 1
        var old_node = previous_root
        var new_node = new_root
        low = 0
        high = distinct
        while high - low > 1:
            let middle = low + (high - low) // 2
            var old_child = Int(left_child[old_node])
            if rank >= middle:
                old_child = Int(right_child[old_node])
            if node_count >= 193:
                return -9223372036854775808
            let new_child = node_count
            node_count += 1
            left_child[new_child] = left_child[old_child]
            right_child[new_child] = right_child[old_child]
            counts[new_child] = counts[old_child] + 1
            if rank < middle:
                left_child[new_node] = Int32(new_child)
                high = middle
            else:
                right_child[new_node] = Int32(new_child)
                low = middle
            old_node = old_child
            new_node = new_child
        roots[i + 1] = Int32(new_root)

    var checksum: Int64 = 0
    for qi in range(q):
        let offset = query_offset + 3 * qi
        let left = Int(input[offset])
        let right = Int(input[offset + 1])
        var k = Int32(input[offset + 2])
        var before = Int(roots[left])
        var after = Int(roots[right + 1])
        var low = 0
        var high = distinct
        while high - low > 1:
            let middle = low + (high - low) // 2
            let in_left = Int(left_child[after])
            let out_left = Int(left_child[before])
            let left_count = counts[in_left] - counts[out_left]
            if k <= left_count:
                before = out_left
                after = in_left
                high = middle
            else:
                k -= left_count
                before = Int(right_child[before])
                after = Int(right_child[after])
                low = middle
        checksum += Int64(qi + 1) * coordinates[low]
    return checksum
