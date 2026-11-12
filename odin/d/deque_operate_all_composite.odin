package deque_operate_all_composite

import "core:c"

Max_Operations :: 64
Max_Input_Length :: 1 + 3 * Max_Operations
Tree_Base :: 128
Tree_Nodes :: 256
Modulus :: i64(998_244_353)

Affine :: struct { a, b: i64 }
Deque_State :: struct {
    tree: [Tree_Nodes]Affine,
    head: int,
    tail: int,
}

identity :: proc "contextless" () -> Affine { return .{a = 1, b = 0} }

compose :: proc "contextless" (first, second: Affine) -> Affine {
    return .{
        a = (second.a * first.a) % Modulus,
        b = (second.a * first.b + second.b) % Modulus,
    }
}

update :: proc "contextless" (deque: ^Deque_State, position: int, value: Affine) {
    node := Tree_Base + position
    deque.tree[node] = value
    for node > 1 {
        node /= 2
        deque.tree[node] = compose(deque.tree[node * 2], deque.tree[node * 2 + 1])
    }
}

@(export)
deque_operate_all_composite :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || length > c.size_t(Max_Input_Length) do return -1
    operation_value := values[0]
    if operation_value < 0 || operation_value > Max_Operations do return -1
    operation_count := int(operation_value)

    deque := Deque_State{head = 64, tail = 64}
    for node := 0; node < Tree_Nodes; node += 1 {
        deque.tree[node] = identity()
    }
    position := 1
    checksum, query_number := i64(0), i64(0)
    for _ := 0; _ < operation_count; _ += 1 {
        if position >= int(length) do return -1
        opcode := values[position]
        position += 1
        if opcode == 0 || opcode == 1 {
            if int(length) - position < 2 do return -1
            a, b := values[position], values[position + 1]
            position += 2
            if a < 1 || a >= Modulus || b < 0 || b >= Modulus do return -1
            function := Affine{a, b}
            if opcode == 0 {
                if deque.head == 0 do return -1
                deque.head -= 1
                update(&deque, deque.head, function)
            } else {
                if deque.tail == Tree_Base do return -1
                update(&deque, deque.tail, function)
                deque.tail += 1
            }
        } else if opcode == 2 || opcode == 3 {
            if deque.head == deque.tail do return -1
            if opcode == 2 {
                update(&deque, deque.head, identity())
                deque.head += 1
            } else {
                deque.tail -= 1
                update(&deque, deque.tail, identity())
            }
        } else if opcode == 4 {
            if position >= int(length) do return -1
            x := values[position]
            position += 1
            if x < 0 || x >= Modulus do return -1
            answer := (deque.tree[1].a * x + deque.tree[1].b) % Modulus
            query_number += 1
            checksum += query_number * (answer + 1)
        } else {
            return -1
        }
    }
    if position != int(length) do return -1
    return checksum
}
