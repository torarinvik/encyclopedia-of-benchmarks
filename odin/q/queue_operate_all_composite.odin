package queue_operate_all_composite

import "core:c"

Max_Operations :: 64
Max_Input_Length :: 1 + 3 * Max_Operations
Modulus :: i64(998_244_353)

Affine :: struct { a, b: i64 }
Queue_State :: struct {
    back_functions: [Max_Operations]Affine,
    back_aggregates: [Max_Operations]Affine,
    front_aggregates: [Max_Operations]Affine,
    back_size: int,
    front_size: int,
}

compose :: proc "contextless" (first, second: Affine) -> Affine {
    return .{
        a = (second.a * first.a) % Modulus,
        b = (second.a * first.b + second.b) % Modulus,
    }
}

push_back :: proc "contextless" (queue: ^Queue_State, a, b: i64) {
    function := Affine{a, b}
    queue.back_functions[queue.back_size] = function
    if queue.back_size == 0 {
        queue.back_aggregates[queue.back_size] = function
    } else {
        queue.back_aggregates[queue.back_size] = compose(queue.back_aggregates[queue.back_size - 1], function)
    }
    queue.back_size += 1
}

transfer :: proc "contextless" (queue: ^Queue_State) {
    for queue.back_size > 0 {
        queue.back_size -= 1
        function := queue.back_functions[queue.back_size]
        if queue.front_size == 0 {
            queue.front_aggregates[queue.front_size] = function
        } else {
            queue.front_aggregates[queue.front_size] = compose(function, queue.front_aggregates[queue.front_size - 1])
        }
        queue.front_size += 1
    }
}

pop_front :: proc "contextless" (queue: ^Queue_State) -> bool {
    if queue.front_size == 0 do transfer(queue)
    if queue.front_size == 0 do return false
    queue.front_size -= 1
    return true
}

aggregate :: proc "contextless" (queue: ^Queue_State) -> Affine {
    result := Affine{1, 0}
    if queue.front_size > 0 do result = queue.front_aggregates[queue.front_size - 1]
    if queue.back_size > 0 {
        if queue.front_size > 0 {
            result = compose(result, queue.back_aggregates[queue.back_size - 1])
        } else {
            result = queue.back_aggregates[queue.back_size - 1]
        }
    }
    return result
}

@(export)
queue_operate_all_composite :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || length > c.size_t(Max_Input_Length) do return -1
    operation_value := values[0]
    if operation_value < 0 || operation_value > Max_Operations do return -1
    operation_count := int(operation_value)

    queue := Queue_State{}
    position := 1
    checksum, query_number := i64(0), i64(0)
    for operation := 0; operation < operation_count; operation += 1 {
        if position >= int(length) do return -1
        opcode := values[position]
        position += 1
        if opcode == 0 {
            if int(length) - position < 2 do return -1
            a, b := values[position], values[position + 1]
            position += 2
            if a < 1 || a >= Modulus || b < 0 || b >= Modulus do return -1
            push_back(&queue, a, b)
        } else if opcode == 1 {
            if !pop_front(&queue) do return -1
        } else if opcode == 2 {
            if position >= int(length) do return -1
            x := values[position]
            position += 1
            if x < 0 || x >= Modulus do return -1
            function := aggregate(&queue)
            answer := (function.a * x + function.b) % Modulus
            query_number += 1
            checksum += query_number * (answer + 1)
        } else {
            return -1
        }
    }
    if position != int(length) do return -1
    return checksum
}
