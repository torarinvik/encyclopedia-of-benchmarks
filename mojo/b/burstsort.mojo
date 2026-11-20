from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_STRINGS = 16
comptime MAX_STRING_LENGTH = 8
comptime MAX_NODES = 129
comptime THRESHOLD = 3
comptime MAX_INPUT_LENGTH = 145

@fieldwise_init
struct BurstNode(Copyable):
    var depth: Int
    var burst: Bool
    var leaf_count: Int
    var terminal_count: Int
    var children: InlineArray[Int, 4]
    var leaf_items: InlineArray[Int, THRESHOLD]
    var terminal_items: InlineArray[Int, MAX_STRINGS]

fn burst_new_node(inout nodes: InlineArray[BurstNode, MAX_NODES],
                  inout used: Int, depth: Int) -> Int:
    if used >= MAX_NODES:
        return -1
    let node_id = used
    used += 1
    var children = InlineArray[Int, 4](fill=-1)
    nodes[node_id] = BurstNode(depth, False, 0, 0, children,
        InlineArray[Int, THRESHOLD](fill=0),
        InlineArray[Int, MAX_STRINGS](fill=0))
    return node_id

fn burst_insert(inout nodes: InlineArray[BurstNode, MAX_NODES],
                inout used: Int, node_id: Int, depth: Int, item: Int,
                inout string_lengths: InlineArray[Int, MAX_STRINGS],
                inout string_bytes: InlineArray[UInt8, MAX_STRINGS * MAX_STRING_LENGTH]) -> Bool:
    if string_lengths[item] == depth:
        if nodes[node_id].terminal_count >= MAX_STRINGS:
            return False
        nodes[node_id].terminal_items[nodes[node_id].terminal_count] = item
        nodes[node_id].terminal_count += 1
        return True

    if not nodes[node_id].burst and nodes[node_id].leaf_count < THRESHOLD:
        nodes[node_id].leaf_items[nodes[node_id].leaf_count] = item
        nodes[node_id].leaf_count += 1
        return True

    if not nodes[node_id].burst:
        var saved = InlineArray[Int, THRESHOLD](fill=0)
        let saved_count = nodes[node_id].leaf_count
        for i in range(saved_count):
            saved[i] = nodes[node_id].leaf_items[i]
        nodes[node_id].leaf_count = 0
        nodes[node_id].burst = True
        for i in range(saved_count):
            if not burst_insert(inout nodes, inout used, node_id, depth,
                    saved[i], inout string_lengths, inout string_bytes):
                return False

    let key = Int(string_bytes[item * MAX_STRING_LENGTH + depth])
    if nodes[node_id].children[key] < 0:
        let child = burst_new_node(inout nodes, inout used, depth + 1)
        if child < 0:
            return False
        nodes[node_id].children[key] = child
    return burst_insert(inout nodes, inout used, nodes[node_id].children[key],
        depth + 1, item, inout string_lengths, inout string_bytes)

fn burst_string_less(left: Int, right: Int,
                     inout string_lengths: InlineArray[Int, MAX_STRINGS],
                     inout string_bytes: InlineArray[UInt8, MAX_STRINGS * MAX_STRING_LENGTH]) -> Bool:
    let left_length = string_lengths[left]
    let right_length = string_lengths[right]
    let common = min(left_length, right_length)
    for i in range(common):
        let left_byte = string_bytes[left * MAX_STRING_LENGTH + i]
        let right_byte = string_bytes[right * MAX_STRING_LENGTH + i]
        if left_byte != right_byte:
            return left_byte < right_byte
    return left_length < right_length

fn burst_emit(inout nodes: InlineArray[BurstNode, MAX_NODES], node_id: Int,
              inout output: InlineArray[Int, MAX_STRINGS], inout output_count: Int,
              inout string_lengths: InlineArray[Int, MAX_STRINGS],
              inout string_bytes: InlineArray[UInt8, MAX_STRINGS * MAX_STRING_LENGTH]):
    for i in range(nodes[node_id].terminal_count):
        output[output_count] = nodes[node_id].terminal_items[i]
        output_count += 1
    if nodes[node_id].burst:
        for key in range(4):
            let child = nodes[node_id].children[key]
            if child >= 0:
                burst_emit(inout nodes, child, inout output, inout output_count,
                    inout string_lengths, inout string_bytes)
        return

    var ordered = InlineArray[Int, THRESHOLD](fill=0)
    for i in range(nodes[node_id].leaf_count):
        ordered[i] = nodes[node_id].leaf_items[i]
    for i in range(1, nodes[node_id].leaf_count):
        let item = ordered[i]
        var position = i
        while position > 0 and burst_string_less(item, ordered[position - 1],
                inout string_lengths, inout string_bytes):
            ordered[position] = ordered[position - 1]
            position -= 1
        ordered[position] = item
    for i in range(nodes[node_id].leaf_count):
        output[output_count] = ordered[i]
        output_count += 1

@export("burstsort")
fn burstsort(input: UnsafePointer[Int64, ImmutAnyOrigin],
             length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    if input[0] < 0 or input[0] > MAX_STRINGS:
        return -1
    let count = Int(input[0])
    var string_lengths = InlineArray[Int, MAX_STRINGS](fill=0)
    var string_bytes = InlineArray[UInt8, MAX_STRINGS * MAX_STRING_LENGTH](fill=0)

    var cursor = 1
    for item in range(count):
        if cursor >= Int(length):
            return -1
        let raw_length = input[cursor]
        cursor += 1
        if raw_length < 0 or raw_length > MAX_STRING_LENGTH:
            return -1
        let string_length = Int(raw_length)
        if string_length > Int(length) - cursor:
            return -1
        string_lengths[item] = string_length
        for j in range(string_length):
            let byte = input[cursor]
            cursor += 1
            if byte < 0 or byte > 3:
                return -1
            string_bytes[item * MAX_STRING_LENGTH + j] = UInt8(byte)
    if cursor != Int(length):
        return -1

    var nodes = InlineArray[BurstNode, MAX_NODES](fill=BurstNode(0, False, 0, 0,
        InlineArray[Int, 4](fill=-1), InlineArray[Int, THRESHOLD](fill=0),
        InlineArray[Int, MAX_STRINGS](fill=0)))
    var used = 0
    let root = burst_new_node(inout nodes, inout used, 0)
    if root < 0:
        return -1
    for item in range(count):
        if not burst_insert(inout nodes, inout used, root, 0, item,
                inout string_lengths, inout string_bytes):
            return -1

    var sorted = InlineArray[Int, MAX_STRINGS](fill=0)
    var sorted_count = 0
    burst_emit(inout nodes, root, inout sorted, inout sorted_count,
        inout string_lengths, inout string_bytes)
    if sorted_count != count:
        return -1

    var powers = InlineArray[Int64, 8](fill=0)
    powers[0] = 78125; powers[1] = 15625; powers[2] = 3125; powers[3] = 625
    powers[4] = 125; powers[5] = 25; powers[6] = 5; powers[7] = 1
    var checksum: Int64 = 0
    for rank in range(count):
        let item = sorted[rank]
        var key: Int64 = 0
        for j in range(string_lengths[item]):
            key += Int64(string_bytes[item * MAX_STRING_LENGTH + j] + 1) * powers[j]
        checksum += Int64(rank + 1) * key
    return checksum
