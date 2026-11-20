from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_OPERATIONS = 64
comptime MAX_INPUT_LENGTH = 193
comptime MAX_NODES = 1024
comptime MAX_HEAP_SIZE = 128
comptime EMPTY_RANK: Int64 = 20001

fn allocate_node(inout keys: InlineArray[Int64, MAX_NODES],
        inout left: InlineArray[Int, MAX_NODES],
        inout right: InlineArray[Int, MAX_NODES],
        inout npl: InlineArray[Int, MAX_NODES], inout used: Int,
        key: Int64, left_child: Int, right_child: Int, null_path_length: Int) -> Int:
    if used >= MAX_NODES:
        return -1
    let node = used
    used += 1
    keys[node] = key
    left[node] = left_child
    right[node] = right_child
    npl[node] = null_path_length
    return node

fn meld(inout keys: InlineArray[Int64, MAX_NODES],
        inout left: InlineArray[Int, MAX_NODES],
        inout right: InlineArray[Int, MAX_NODES],
        inout npl: InlineArray[Int, MAX_NODES], inout used: Int,
        left_root_input: Int, right_root_input: Int) -> Int:
    if left_root_input < 0 or right_root_input < 0:
        return -1
    if left_root_input == 0:
        return right_root_input
    if right_root_input == 0:
        return left_root_input
    var left_root = left_root_input
    var right_root = right_root_input
    if keys[left_root] > keys[right_root]:
        let temporary = left_root
        left_root = right_root
        right_root = temporary

    let winner_key = keys[left_root]
    let winner_left = left[left_root]
    let winner_right = right[left_root]
    let winner_npl = npl[left_root]
    let copy = allocate_node(inout keys, inout left, inout right, inout npl,
        inout used, winner_key, winner_left, winner_right, winner_npl)
    if copy < 0:
        return -1
    let merged_right = meld(inout keys, inout left, inout right, inout npl,
        inout used, winner_right, right_root)
    if merged_right < 0:
        return -1
    right[copy] = merged_right
    if npl[left[copy]] < npl[right[copy]]:
        let temporary = left[copy]
        left[copy] = right[copy]
        right[copy] = temporary
    npl[copy] = npl[right[copy]] + 1
    return copy

@export("persistent_leftist_heap")
fn persistent_leftist_heap(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    let input_length = Int(length)
    let raw_operations = input[0]
    if raw_operations < 0 or raw_operations > MAX_OPERATIONS:
        return -1
    let operation_count = Int(raw_operations)

    var keys = InlineArray[Int64, MAX_NODES](fill=0)
    var left = InlineArray[Int, MAX_NODES](fill=0)
    var right = InlineArray[Int, MAX_NODES](fill=0)
    var npl = InlineArray[Int, MAX_NODES](fill=0)
    npl[0] = -1
    var used = 1
    var roots = InlineArray[Int, MAX_OPERATIONS + 1](fill=0)
    var sizes = InlineArray[Int, MAX_OPERATIONS + 1](fill=0)
    var observation_sum: Int64 = 0
    var observation_xor: Int64 = 0
    var cursor = 1

    for operation_index in range(operation_count):
        if cursor >= input_length:
            return -1
        let operation = input[cursor]
        cursor += 1
        var first: Int64 = 0
        var second: Int64 = 0
        if operation == 0 or operation == 1:
            if input_length - cursor < 2:
                return -1
            first = input[cursor]
            second = input[cursor + 1]
            cursor += 2
        elif operation == 2 or operation == 3:
            if input_length - cursor < 1:
                return -1
            first = input[cursor]
            cursor += 1
        else:
            return -1

        var new_root = 0
        var new_size = 0
        if operation == 0:
            if first < 0 or first > operation_index or second < -10000 or second > 10000:
                return -1
            let base = Int(first)
            if sizes[base] >= MAX_HEAP_SIZE:
                return -1
            let singleton = allocate_node(inout keys, inout left, inout right,
                inout npl, inout used, second, 0, 0, 0)
            if singleton < 0:
                return -1
            new_root = meld(inout keys, inout left, inout right, inout npl,
                inout used, roots[base], singleton)
            if new_root < 0:
                return -1
            new_size = sizes[base] + 1
        elif operation == 1:
            if first < 0 or first > operation_index or second < 0 or second > operation_index:
                return -1
            let left_version = Int(first)
            let right_version = Int(second)
            new_size = sizes[left_version] + sizes[right_version]
            if new_size > MAX_HEAP_SIZE:
                return -1
            new_root = meld(inout keys, inout left, inout right, inout npl,
                inout used, roots[left_version], roots[right_version])
            if new_root < 0:
                return -1
        else:
            if first < 0 or first > operation_index:
                return -1
            let version = Int(first)
            let root = roots[version]
            var rank = EMPTY_RANK
            if root != 0:
                rank = keys[root] + 10000
            observation_sum += rank
            observation_xor ^= rank
            if operation == 3:
                new_root = root
                new_size = sizes[version]
            elif root != 0:
                new_root = meld(inout keys, inout left, inout right, inout npl,
                    inout used, left[root], right[root])
                if new_root < 0:
                    return -1
                new_size = sizes[version] - 1

        if new_size > MAX_HEAP_SIZE:
            return -1
        roots[operation_index + 1] = new_root
        sizes[operation_index + 1] = new_size

    if cursor != input_length:
        return -1
    return (observation_sum << 15) | observation_xor
