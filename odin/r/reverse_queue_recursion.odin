package reverse_queue_recursion

import "core:c"

MAX_QUEUE_LENGTH :: 32
MAX_INPUT_LENGTH :: 34

reverse_queue_recursive :: proc "contextless" (
    queue: [^]u8, capacity: int, front, size: ^int,
) {
    if size^ == 0 do return
    value := queue[front^]
    front^ = (front^ + 1) % capacity
    size^ -= 1
    reverse_queue_recursive(queue, capacity, front, size)
    rear := (front^ + size^) % capacity
    queue[rear] = value
    size^ += 1
}

@(export)
reverse_queue_recursion :: proc "c" (
    input: [^]i64, input_length: c.size_t,
    output: [^]u8, output_capacity: c.size_t,
) -> i64 {
    if input == nil {
        if input_length != 1 do return -1
        if output == nil do return -2
        return 0
    }
    if input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
    if input[0] < 0 || input[0] > MAX_QUEUE_LENGTH do return -1
    queue_length := int(input[0])
    if int(input_length) != queue_length + 1 do return -1
    for index := 0; index < queue_length; index += 1 {
        if input[index + 1] < 0 || input[index + 1] > 255 do return -1
    }
    if output == nil || output_capacity < queue_length do return -2

    queue: [MAX_QUEUE_LENGTH]u8
    for index := 0; index < queue_length; index += 1 { queue[index] = u8(input[index + 1]) }
    front := 0
    size := queue_length
    reverse_queue_recursive(&queue[0], queue_length, &front, &size)
    for index := 0; index < queue_length; index += 1 {
        output[index] = queue[(front + index) % queue_length]
    }
    return i64(queue_length)
}
