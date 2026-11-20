from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_ROOT = 444
const MAX_PARSEABLE_LENGTH = 2

@fieldwise_init
struct TaxicabNode(Copyable):
    var sum: Int32
    var a: Int32
    var b: Int32

fn node_less(left: TaxicabNode, right: TaxicabNode) -> Bool:
    if left.sum != right.sum: return left.sum < right.sum
    if left.a != right.a: return left.a < right.a
    return left.b < right.b

fn heap_push(inout heap: InlineArray[TaxicabNode, 444], inout size: Int, node: TaxicabNode):
    var index = size
    size += 1
    while index > 0:
        let parent = (index - 1) // 2
        if not node_less(node, heap[parent]): break
        heap[index] = heap[parent]
        index = parent
    heap[index] = node

fn heap_pop(inout heap: InlineArray[TaxicabNode, 444], inout size: Int) -> TaxicabNode:
    let result = heap[0]
    size -= 1
    if size == 0: return result
    let last = heap[size]
    var index = 0
    while 2 * index + 1 < size:
        var child = 2 * index + 1
        if child + 1 < size and node_less(heap[child + 1], heap[child]): child += 1
        if not node_less(heap[child], last): break
        heap[index] = heap[child]
        index = child
    heap[index] = last
    return result

fn cube(value: Int32) -> Int32:
    return value * value * value

fn search(ways: Int32) -> Int64:
    var heap = InlineArray[TaxicabNode, 444](fill=TaxicabNode(0, 0, 0))
    var size = 0
    for a in range(1, MAX_ROOT + 1):
        let root = Int32(a)
        let value = cube(root)
        heap_push(heap, size, TaxicabNode(sum=2 * value, a=root, b=root))
    while size > 0:
        let first = heap_pop(heap, size)
        let total = first.sum
        var count: Int32 = 1
        if first.b < Int32(MAX_ROOT):
            let next_b = first.b + 1
            heap_push(heap, size, TaxicabNode(sum=cube(first.a) + cube(next_b), a=first.a, b=next_b))
        while size > 0 and heap[0].sum == total:
            let equal = heap_pop(heap, size)
            count += 1
            if equal.b < Int32(MAX_ROOT):
                let next_b = equal.b + 1
                heap_push(heap, size, TaxicabNode(sum=cube(equal.a) + cube(next_b), a=equal.a, b=next_b))
        if count >= ways: return Int64(total)
    return -1

@export("taxicab_number_minimum_representations")
fn taxicab_number_minimum_representations(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    if length != 1: return -1
    let ways = input[0]
    if ways != 2 and ways != 3: return -1
    return search(Int32(ways))
