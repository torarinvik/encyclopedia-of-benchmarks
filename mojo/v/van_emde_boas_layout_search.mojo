from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_HEIGHT = 4
comptime MAX_NODES = 15
comptime MAX_QUERIES = 4
comptime MAX_WORDS = 41

fn fill_keys(inout keys: InlineArray[Int64, MAX_NODES + 1],
             heap: Int, low: Int, high: Int):
    if low > high:
        return
    let middle = low + (high - low) // 2
    keys[heap] = Int64(middle)
    fill_keys(inout keys, heap * 2, low, middle - 1)
    fill_keys(inout keys, heap * 2 + 1, middle + 1, high)

fn emit_layout(inout order: InlineArray[Int64, MAX_NODES],
               inout used: Int, root: Int, height: Int):
    if height == 1:
        order[used] = Int64(root)
        used += 1
        return
    let top_height = height // 2
    let bottom_height = height - top_height
    emit_layout(inout order, inout used, root, top_height)
    let bottom_count = 1 << top_height
    for offset in range(bottom_count):
        emit_layout(inout order, inout used,
                    root * bottom_count + offset, bottom_height)

@export("van_emde_boas_layout_search")
fn van_emde_boas_layout_search(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 7:
        return -1
    let height_value = input[0]
    let query_value = input[1]
    if height_value < 1 or height_value > MAX_HEIGHT or query_value < 0 or query_value > MAX_QUERIES:
        return -1
    let height = Int(height_value)
    let query_count = Int(query_value)
    if length != c_size_t(2 + query_count):
        return -1
    let node_count = (1 << height) - 1
    for query in range(query_count):
        let key = input[2 + query]
        if key < -1 or key > node_count:
            return -1

    var order = InlineArray[Int64, MAX_NODES](fill=0)
    var keys = InlineArray[Int64, MAX_NODES + 1](fill=0)
    var slots = InlineArray[Int64, MAX_NODES + 1](fill=0)
    var staged = InlineArray[Int64, MAX_WORDS](fill=0)
    var used = 0
    emit_layout(inout order, inout used, 1, height)
    fill_keys(inout keys, 1, 0, node_count - 1)
    for slot in range(node_count):
        slots[Int(order[slot])] = Int64(slot)

    var out = 0
    staged[out] = Int64(node_count)
    out += 1
    for slot in range(node_count):
        staged[out] = order[slot]
        out += 1
    staged[out] = Int64(query_count)
    out += 1
    for query in range(query_count):
        let key = input[2 + query]
        var heap = 1
        let path_start = out
        out += 1
        var path_length = 0
        var found: Int64 = -1
        while heap <= node_count:
            staged[out] = slots[heap]
            out += 1
            path_length += 1
            if key == keys[heap]:
                found = Int64(heap)
                break
            if key < keys[heap]:
                heap *= 2
            else:
                heap = heap * 2 + 1
        staged[path_start] = Int64(path_length)
        staged[out] = found
        out += 1
    let required = c_size_t(out * 8)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < required:
        return -2
    for word in range(out):
        let bits = UInt64(staged[word])
        for byte in range(8):
            output[word * 8 + byte] = UInt8((bits >> (8 * byte)) & 0xFF)
    return Int64(required)
