from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn heap_pop(mut heap: List[Int64]) -> Int64:
    let result = heap[0]
    let last = heap.pop()
    if len(heap) > 0:
        heap[0] = last
        var i = 0
        while True:
            let left = 2 * i + 1; let right = left + 1; var child = i
            if left < len(heap) and heap[left] < heap[child]: child = left
            if right < len(heap) and heap[right] < heap[child]: child = right
            if child == i: break
            let t = heap[i]; heap[i] = heap[child]; heap[child] = t; i = child
    return result

fn append_word(mut bytes: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8): bytes.append(UInt8(bits & 255)); bits >>= 8

@export("binary_heap_min_push_peek_pop")
fn binary_heap_min_push_peek_pop(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 257: return -1
    let count_value = input[0]
    if count_value < 1 or count_value > 256 or length != c_size_t(count_value + 1): return -1
    let n = Int(count_value)
    for i in range(n):
        if input[1 + i] < -2_147_483_648 or input[1 + i] > 2_147_483_647: return -1
    let needed = n * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    var heap = List[Int64](capacity=n)
    for i in range(n):
        heap.append(input[1 + i]); var j = len(heap) - 1
        while j > 0:
            let p = (j - 1) // 2
            if heap[p] <= heap[j]: break
            let t = heap[p]; heap[p] = heap[j]; heap[j] = t; j = p
    var bytes = List[UInt8](capacity=needed)
    for _ in range(n): append_word(bytes, heap_pop(heap))
    for i in range(needed): output[i] = bytes[i]
    return Int64(needed)
