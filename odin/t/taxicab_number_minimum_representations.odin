package taxicab_number_minimum_representations

import "core:c"

Max_Root :: 444
Max_Parseable_Length :: 2

Node :: struct { sum: i32, a: i32, b: i32 }

node_less :: proc "contextless" (left, right: Node) -> bool {
    if left.sum != right.sum do return left.sum < right.sum
    if left.a != right.a do return left.a < right.a
    return left.b < right.b
}

heap_push :: proc "contextless" (heap: ^[Max_Root]Node, size: ^int, node: Node) {
    index := size^
    size^ += 1
    for index > 0 {
        parent := (index - 1) / 2
        if !node_less(node, heap^[parent]) do break
        heap^[index] = heap^[parent]
        index = parent
    }
    heap^[index] = node
}

heap_pop :: proc "contextless" (heap: ^[Max_Root]Node, size: ^int) -> Node {
    result := heap^[0]
    size^ -= 1
    if size^ == 0 do return result
    last := heap^[size^]
    index := 0
    for 2 * index + 1 < size^ {
        child := 2 * index + 1
        if child + 1 < size^ && node_less(heap^[child + 1], heap^[child]) do child += 1
        if !node_less(heap^[child], last) do break
        heap^[index] = heap^[child]
        index = child
    }
    heap^[index] = last
    return result
}

cube :: proc "contextless" (value: i32) -> i32 { return value * value * value }

search :: proc "contextless" (ways: i32) -> i64 {
    heap: [Max_Root]Node = {}
    size := 0
    for a := 1; a <= Max_Root; a += 1 {
        root := i32(a)
        value := cube(root)
        heap_push(&heap, &size, Node{2 * value, root, root})
    }
    for size > 0 {
        first := heap_pop(&heap, &size)
        total := first.sum
        count := 1
        if first.b < Max_Root {
            next_b := first.b + 1
            heap_push(&heap, &size, Node{cube(first.a) + cube(next_b), first.a, next_b})
        }
        for size > 0 && heap[0].sum == total {
            equal := heap_pop(&heap, &size)
            count += 1
            if equal.b < Max_Root {
                next_b := equal.b + 1
                heap_push(&heap, &size, Node{cube(equal.a) + cube(next_b), equal.a, next_b})
            }
        }
        if count >= ways do return i64(total)
    }
    return -1
}

@(export)
taxicab_number_minimum_representations :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(Max_Parseable_Length) do return -1
    if length != 1 || (input[0] != 2 && input[0] != 3) do return -1
    return search(i32(input[0]))
}
