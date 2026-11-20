from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("unshuffle_sort")
fn unshuffle_sort(values: UnsafePointer[Int64, MutAnyOrigin],
                  scratch: UnsafePointer[Int64, MutAnyOrigin],
                  length: c_size_t) abi("C"):
    if values == UnsafePointer[Int64, MutAnyOrigin]() or scratch == UnsafePointer[Int64, MutAnyOrigin]():
        return
    if length < 2 or length > 1024:
        return
    let n = Int(length)
    let none = UInt32(1024)
    var previous = InlineArray[UInt32, 1024]()
    var next = InlineArray[UInt32, 1024]()
    var pile_front = InlineArray[UInt32, 1024]()
    var pile_back = InlineArray[UInt32, 1024]()
    var heap = InlineArray[UInt32, 1024]()
    var pile_count = 0

    for node in range(n):
        previous[node] = none
        next[node] = none
        var pile = 0
        while pile < pile_count:
            let front = Int(pile_front[pile])
            let back = Int(pile_back[pile])
            if values[node] <= values[front]:
                next[node] = pile_front[pile]
                previous[front] = UInt32(node)
                pile_front[pile] = UInt32(node)
                break
            if values[node] >= values[back]:
                previous[node] = pile_back[pile]
                next[back] = UInt32(node)
                pile_back[pile] = UInt32(node)
                break
            pile += 1
        if pile == pile_count:
            pile_front[pile_count] = UInt32(node)
            pile_back[pile_count] = UInt32(node)
            pile_count += 1

    var heap_size = 0
    for pile in range(pile_count):
        var position = heap_size
        heap[position] = UInt32(pile)
        heap_size += 1
        while position > 0:
            let parent = (position - 1) // 2
            let left_node = Int(pile_front[Int(heap[position])])
            let parent_node = Int(pile_front[Int(heap[parent])])
            let less = values[left_node] < values[parent_node] or (
                values[left_node] == values[parent_node] and heap[position] < heap[parent]
            )
            if not less:
                break
            let temporary = heap[position]
            heap[position] = heap[parent]
            heap[parent] = temporary
            position = parent

    var output = 0
    while heap_size > 0:
        let pile = Int(heap[0])
        let node = Int(pile_front[pile])
        scratch[output] = values[node]
        output += 1
        let successor = next[node]
        if successor != none:
            previous[Int(successor)] = none
            next[node] = none
            pile_front[pile] = successor
        else:
            pile_front[pile] = none
            pile_back[pile] = none
            heap_size -= 1
            if heap_size > 0:
                heap[0] = heap[heap_size]
        if heap_size > 0:
            var position = 0
            while position * 2 + 1 < heap_size:
                var child = position * 2 + 1
                if child + 1 < heap_size:
                    let right_node = Int(pile_front[Int(heap[child + 1])])
                    let left_node = Int(pile_front[Int(heap[child])])
                    if values[right_node] < values[left_node] or (
                        values[right_node] == values[left_node] and heap[child + 1] < heap[child]
                    ):
                        child += 1
                let child_node = Int(pile_front[Int(heap[child])])
                let position_node = Int(pile_front[Int(heap[position])])
                let less = values[child_node] < values[position_node] or (
                    values[child_node] == values[position_node] and heap[child] < heap[position]
                )
                if not less:
                    break
                let temporary = heap[position]
                heap[position] = heap[child]
                heap[child] = temporary
                position = child

    for index in range(n):
        values[index] = scratch[index]
