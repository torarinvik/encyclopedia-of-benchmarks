from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_LISTS = 16
comptime MAX_TOTAL_NODES = 128
comptime MAX_INPUT_LENGTH = 145


fn write_i32_le(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
):
    let bits = UInt32(Int32(value))
    for byte in range(4):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt32(255))


fn packed_node_key(value: Int64, list_index: Int, node_index: Int) -> Int64:
    return (value + 2147483648) * 2048 + Int64(list_index * 128 + node_index)


@export("merge_ksorted_linked_list")
fn merge_ksorted_linked_list(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let list_count = input[0]
    if list_count < 0 or list_count > MAX_LISTS:
        return -1

    var starts = InlineArray[Int64, MAX_LISTS](fill=0)
    var list_lengths = InlineArray[Int64, MAX_LISTS](fill=0)
    var position = 1
    var total_nodes = 0
    for list_index in range(Int(list_count)):
        if position >= Int(length):
            return -1
        let declared = input[position]
        position += 1
        if declared < 0 or declared > MAX_TOTAL_NODES - total_nodes:
            return -1
        let node_count = Int(declared)
        if node_count > Int(length) - position:
            return -1
        starts[list_index] = Int64(position)
        list_lengths[list_index] = declared
        for node_index in range(node_count):
            let value = input[position + node_index]
            if value < -2147483648 or value > 2147483647:
                return -1
            if node_index > 0 and input[position + node_index - 1] > value:
                return -1
        position += node_count
        total_nodes += node_count
    if position != Int(length):
        return -1

    let output_bytes = total_nodes * 4
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    # A binary min-heap of packed (value, list, node) keys preserves the
    # priority-queue merge order and deterministic ties from the source.
    var heap = InlineArray[Int64, MAX_LISTS](fill=0)
    var heap_size = 0
    for list_index in range(Int(list_count)):
        if list_lengths[list_index] > 0:
            let value = input[Int(starts[list_index])]
            let key = packed_node_key(value, list_index, 0)
            var index = heap_size
            heap_size += 1
            while index > 0:
                let parent = (index - 1) // 2
                if heap[parent] <= key:
                    break
                heap[index] = heap[parent]
                index = parent
            heap[index] = key

    var written = 0
    while heap_size > 0:
        let key = heap[0]
        let biased_value = key // 2048
        let tie_breaker = key % 2048
        let list_index = Int(tie_breaker // 128)
        let node_index = Int(tie_breaker % 128)
        let value = biased_value - 2147483648
        write_i32_le(output, written * 4, value)
        written += 1

        let last = heap[heap_size - 1]
        heap_size -= 1
        if heap_size > 0:
            var index = 0
            while index < heap_size // 2:
                var child = index * 2 + 1
                if child + 1 < heap_size and heap[child + 1] < heap[child]:
                    child += 1
                if heap[child] >= last:
                    break
                heap[index] = heap[child]
                index = child
            heap[index] = last

        let next_node = node_index + 1
        if next_node < Int(list_lengths[list_index]):
            let next_value = input[Int(starts[list_index]) + next_node]
            let next_key = packed_node_key(next_value, list_index, next_node)
            var index = heap_size
            heap_size += 1
            while index > 0:
                let parent = (index - 1) // 2
                if heap[parent] <= next_key:
                    break
                heap[index] = heap[parent]
                index = parent
            heap[index] = next_key
    return Int64(output_bytes)
