from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer


fn psh_before(best: InlineArray[Int64, 64], left: Int, right: Int) -> Bool:
    return best[left] < best[right] or (best[left] == best[right] and left < right)


fn psh_exchange(inout heap: InlineArray[Int, 64], inout position: InlineArray[Int, 64], first: Int, second: Int):
    let saved = heap[first]
    heap[first] = heap[second]
    heap[second] = saved
    position[heap[first]] = first
    position[heap[second]] = second


fn psh_sift_up(inout heap: InlineArray[Int, 64], inout position: InlineArray[Int, 64],
               best: InlineArray[Int64, 64], start: Int):
    var at = start
    while at > 0:
        let parent = (at - 1) // 2
        if not psh_before(best, heap[at], heap[parent]):
            break
        psh_exchange(heap, position, at, parent)
        at = parent


fn psh_pop_min(inout heap: InlineArray[Int, 64], inout position: InlineArray[Int, 64],
               inout count: Int, best: InlineArray[Int64, 64]) -> Int:
    let result = heap[0]
    position[result] = 64
    count -= 1
    if count > 0:
        let last = heap[count]
        var at = 0
        while 2 * at + 1 < count:
            var child = 2 * at + 1
            if child + 1 < count and psh_before(best, heap[child + 1], heap[child]):
                child += 1
            if not psh_before(best, heap[child], last):
                break
            heap[at] = heap[child]
            position[heap[at]] = at
            at = child
        heap[at] = last
        position[last] = at
    return result


@export("prim_sparse_heap")
fn prim_sparse_heap(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 12290:
        return -2
    let vertex_word = values[0]
    let edge_word = values[1]
    if vertex_word < 0 or vertex_word > 64 or edge_word < 0 or edge_word > 4096:
        return -2
    let vertices = Int(vertex_word)
    let edge_count = Int(edge_word)
    if Int(length) != 2 + 3 * edge_count or (vertices == 0 and edge_count != 0):
        return -2
    if vertices == 0:
        return 0
    for edge in range(edge_count):
        let origin = values[2 + 3 * edge]
        let destination = values[3 + 3 * edge]
        let weight = values[4 + 3 * edge]
        if origin < 0 or destination < 0 or origin >= vertex_word or destination >= vertex_word or
            weight < 0 or weight > 2147483647:
            return -2

    var head = InlineArray[Int, 64](fill=8192)
    var next = InlineArray[Int, 8192](fill=8192)
    var to = InlineArray[Int, 8192]()
    var arc_weight = InlineArray[Int64, 8192]()
    var arc_count = 0
    for edge in range(edge_count):
        let origin = Int(values[2 + 3 * edge])
        let destination = Int(values[3 + 3 * edge])
        let weight = values[4 + 3 * edge]
        if origin == destination:
            continue
        to[arc_count] = destination
        arc_weight[arc_count] = weight
        next[arc_count] = head[origin]
        head[origin] = arc_count
        arc_count += 1
        to[arc_count] = origin
        arc_weight[arc_count] = weight
        next[arc_count] = head[destination]
        head[destination] = arc_count
        arc_count += 1

    var best = InlineArray[Int64, 64]()
    var has_best = InlineArray[Bool, 64](fill=False)
    var selected = InlineArray[Bool, 64](fill=False)
    var heap = InlineArray[Int, 64]()
    var position = InlineArray[Int, 64](fill=64)
    heap[0] = 0
    position[0] = 0
    has_best[0] = True
    var heap_count = 1
    var selected_count = 0
    var total = Int64(0)
    while heap_count > 0:
        let origin = psh_pop_min(heap, position, heap_count, best)
        selected[origin] = True
        selected_count += 1
        total += best[origin]
        var arc = head[origin]
        while arc != 8192:
            let destination = to[arc]
            let weight = arc_weight[arc]
            if not selected[destination] and (not has_best[destination] or weight < best[destination]):
                best[destination] = weight
                has_best[destination] = True
                if position[destination] == 64:
                    heap[heap_count] = destination
                    position[destination] = heap_count
                    heap_count += 1
                psh_sift_up(heap, position, best, position[destination])
            arc = next[arc]
    if selected_count == vertices:
        return total
    return -1
