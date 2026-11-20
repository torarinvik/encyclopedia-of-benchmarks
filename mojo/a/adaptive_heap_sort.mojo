from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

alias MAX_VALUES = 1024

fn node_less(values: UnsafePointer[Int64, MutAnyOrigin], left: Int, right: Int) -> Bool:
    return values[left] < values[right] or (values[left] == values[right] and left < right)

fn push_candidate(values: UnsafePointer[Int64, MutAnyOrigin],
                  mut heap: InlineArray[Int64, MAX_VALUES], mut heap_length: Int,
                  node: Int):
    var position = heap_length
    heap_length += 1
    heap[position] = Int64(node)
    while position > 0:
        let parent = (position - 1) // 2
        if not node_less(values, Int(heap[position]), Int(heap[parent])):
            break
        let temporary = heap[position]
        heap[position] = heap[parent]
        heap[parent] = temporary
        position = parent

fn pop_candidate(values: UnsafePointer[Int64, MutAnyOrigin],
                 mut heap: InlineArray[Int64, MAX_VALUES], mut heap_length: Int) -> Int:
    let minimum = Int(heap[0])
    heap_length -= 1
    if heap_length == 0:
        return minimum
    heap[0] = heap[heap_length]
    var position = 0
    while position < heap_length // 2:
        var child = position * 2 + 1
        if child + 1 < heap_length and node_less(values, Int(heap[child + 1]), Int(heap[child])):
            child += 1
        if not node_less(values, Int(heap[child]), Int(heap[position])):
            break
        let temporary = heap[position]
        heap[position] = heap[child]
        heap[child] = temporary
        position = child
    return minimum

@export("adaptive_heap_sort")
fn adaptive_heap_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    if values == UnsafePointer[Int64, MutAnyOrigin]() or length < 2 or length > MAX_VALUES:
        return
    let count = Int(length)
    var left = InlineArray[Int64, MAX_VALUES](fill=Int64(count))
    var right = InlineArray[Int64, MAX_VALUES](fill=Int64(count))
    var construction_stack = InlineArray[Int64, MAX_VALUES]()
    var candidate_heap = InlineArray[Int64, MAX_VALUES]()
    var output = InlineArray[Int64, MAX_VALUES]()

    var stack_length = 0
    for index in range(count):
        var last = count
        while stack_length > 0 and values[Int(construction_stack[stack_length - 1])] > values[index]:
            stack_length -= 1
            last = Int(construction_stack[stack_length])
        if stack_length > 0:
            right[Int(construction_stack[stack_length - 1])] = Int64(index)
        if last < count:
            left[index] = Int64(last)
        construction_stack[stack_length] = Int64(index)
        stack_length += 1

    var heap_length = 0
    push_candidate(values, mut candidate_heap, mut heap_length, Int(construction_stack[0]))
    for output_index in range(count):
        let node = pop_candidate(values, mut candidate_heap, mut heap_length)
        output[output_index] = values[node]
        if Int(left[node]) < count:
            push_candidate(values, mut candidate_heap, mut heap_length, Int(left[node]))
        if Int(right[node]) < count:
            push_candidate(values, mut candidate_heap, mut heap_length, Int(right[node]))
    for index in range(count):
        values[index] = output[index]
