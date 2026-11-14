from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn heap_less(input: UnsafePointer[Int64, ImmutAnyOrigin], starts: InlineArray[Int, 16],
             positions: InlineArray[Int, 16], a: Int, b: Int) -> Bool:
    let av = input[starts[a] + positions[a]]
    let bv = input[starts[b] + positions[b]]
    return av < bv or (av == bv and a < b)

@export("merge_ksorted_linked_list")
fn merge_ksorted_linked_list(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 145:
        return -1
    if input[0] < 0 or input[0] > 16:
        return -1
    let list_count = Int(input[0])
    var starts = InlineArray[Int, 16](fill=0)
    var sizes = InlineArray[Int, 16](fill=0)
    var positions = InlineArray[Int, 16](fill=0)
    var cursor = 1
    var total = 0
    for list in range(list_count):
        if cursor >= Int(length): return -1
        let raw_size = input[cursor]
        cursor += 1
        if raw_size < 0 or raw_size > Int64(128 - total): return -1
        let size = Int(raw_size)
        if size > Int(length) - cursor: return -1
        starts[list] = cursor
        sizes[list] = size
        for i in range(size):
            let value = input[cursor + i]
            if value < -2147483648 or value > 2147483647: return -1
            if i > 0 and input[cursor + i - 1] > value: return -1
        cursor += size
        total += size
    if cursor != Int(length): return -1
    let byte_count = 4 * total
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count):
        return -2
    var heap = InlineArray[Int, 16](fill=0)
    var heap_size = 0
    for list in range(list_count):
        if sizes[list] > 0:
            var index = heap_size
            heap_size += 1
            while index > 0:
                let parent = (index - 1) // 2
                if not heap_less(input, starts, positions, list, heap[parent]): break
                heap[index] = heap[parent]
                index = parent
            heap[index] = list
    var written = 0
    while heap_size > 0:
        let list = heap[0]
        let value = input[starts[list] + positions[list]]
        for byte in range(4):
            output[written + byte] = UInt8((value >> (8 * byte)) & 255)
        written += 4
        positions[list] += 1
        if positions[list] == sizes[list]:
            heap_size -= 1
            if heap_size > 0: heap[0] = heap[heap_size]
        var index = 0
        while index * 2 + 1 < heap_size:
            var child = index * 2 + 1
            if child + 1 < heap_size and heap_less(input, starts, positions, heap[child + 1], heap[child]):
                child += 1
            if not heap_less(input, starts, positions, heap[child], heap[index]): break
            let temporary = heap[index]
            heap[index] = heap[child]
            heap[child] = temporary
            index = child
    return Int64(byte_count)
