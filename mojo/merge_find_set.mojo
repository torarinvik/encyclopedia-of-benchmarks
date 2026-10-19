from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 256
comptime MAX_MERGES = 512
comptime MAX_INPUT_LENGTH = 1028


@export("merge_find_set")
fn merge_find_set(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let n = input[0]
    let merge_count = input[1]
    if n < 1 or n > MAX_N or merge_count < 0 or merge_count > MAX_MERGES:
        return -1
    if Int(length) != 2 * Int(merge_count) + 3:
        return -1

    var parent = InlineArray[Int64, MAX_N](fill=0)
    var rank = InlineArray[Int64, MAX_N](fill=0)
    for element in range(Int(n)):
        parent[element] = Int64(element)

    for operation in range(Int(merge_count)):
        let position = 2 + 2 * operation
        let first = input[position]
        let second = input[position + 1]
        if first < 0 or second < 0 or first >= n or second >= n:
            return -1
        var first_root = first
        var second_root = second
        while parent[Int(first_root)] != first_root:
            first_root = parent[Int(first_root)]
        while parent[Int(second_root)] != second_root:
            second_root = parent[Int(second_root)]
        if first_root != second_root:
            if rank[Int(first_root)] < rank[Int(second_root)]:
                parent[Int(first_root)] = second_root
            elif rank[Int(first_root)] > rank[Int(second_root)]:
                parent[Int(second_root)] = first_root
            else:
                parent[Int(first_root)] = second_root
                rank[Int(second_root)] += 1

    var query = input[Int(length) - 1]
    if query < 0 or query >= n:
        return -1
    while parent[Int(query)] != query:
        query = parent[Int(query)]
    return query
