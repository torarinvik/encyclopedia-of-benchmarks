from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn bubble_up(mut heap: List[Int64], index_in: Int):
    var i = index_in
    while i > 0:
        let parent = (i - 1) // 2
        if heap[parent] <= heap[i]: break
        let t = heap[parent]; heap[parent] = heap[i]; heap[i] = t; i = parent

fn remove_min(mut heap: List[Int64], mut size: Int) -> Int64:
    if size == 0: return 2_147_483_647
    let result = heap[0]
    size -= 1
    if size > 0:
        heap[0] = heap[size]
        var i = 0
        while True:
            let left = 2 * i + 1; let right = left + 1
            var smallest = i
            if left < size and heap[left] < heap[smallest]: smallest = left
            if right < size and heap[right] < heap[smallest]: smallest = right
            if smallest == i: break
            let t = heap[i]; heap[i] = heap[smallest]; heap[smallest] = t; i = smallest
    _ = heap.pop()
    return result

fn append_word(mut bytes: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8): bytes.append(UInt8(bits & 255)); bits >>= 8

@export("binary_heap_indexed_operations")
fn binary_heap_indexed_operations(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1
    let cap = input[0]; let count_value = input[1]
    if cap < 1 or cap > 256 or count_value < 0 or count_value > 512 or length != c_size_t(2 + 3 * count_value): return -1
    let count = Int(count_value); var heap = List[Int64](capacity=Int(cap)); var size = 0
    var results = List[Int64](capacity=count)
    for i in range(count):
        let op = input[2 + 3 * i]; let a = input[3 + 3 * i]; let b = input[4 + 3 * i]
        if op == 0:
            if a < -2_147_483_648 or a > 2_147_483_647 or b != 0: return -1
            if size < cap: heap.append(a); bubble_up(heap, size); size += 1
        elif op == 1 or op == 2:
            if a != 0 or b != 0 or (op == 1 and size == 0): return -1
            if op == 1: results.append(heap[0])
            else: results.append(remove_min(heap, size))
        elif op == 3:
            if a < 0 or a >= size or b < -2_147_483_648 or b > 2_147_483_647 or b > heap[Int(a)]: return -1
            heap[Int(a)] = b; bubble_up(heap, Int(a))
        elif op == 4:
            if a < 0 or a >= size or b != 0: return -1
            heap[Int(a)] = -2_147_483_648; bubble_up(heap, Int(a)); _ = remove_min(heap, size)
        else: return -1
    let needed = len(results) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    var bytes = List[UInt8](capacity=needed)
    for v in results: append_word(bytes, v)
    for i in range(needed): output[i] = bytes[i]
    return Int64(needed)
