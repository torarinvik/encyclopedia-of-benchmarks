from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("find_kth_number")
fn find_kth_number(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 1025: return -9223372036854775808
    let k = values[0]
    let n = Int64(length) - 1
    if k < 1 or k > n: return -9223372036854775808
    var heap = InlineArray[Int32, 1024](0)
    for i in range(n):
        let x = values[i + 1]
        if x < -2147483648 or x > 2147483647: return -9223372036854775808
        var index = i
        heap[index] = Int32(x)
        while index > 0:
            let parent = (index - 1) / 2
            if heap[parent] >= heap[index]: break
            let temp = heap[parent]
            heap[parent] = heap[index]
            heap[index] = temp
            index = parent
    var size = n
    for removed in range(1, k):
        size -= 1
        heap[0] = heap[size]
        var index: Int64 = 0
        while index * 2 + 1 < size:
            var child = index * 2 + 1
            if child + 1 < size and heap[child + 1] > heap[child]: child += 1
            if heap[index] >= heap[child]: break
            let temp = heap[index]
            heap[index] = heap[child]
            heap[child] = temp
            index = child
    return Int64(heap[0])
