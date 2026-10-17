package priority_queues

import "core:c"

MAX_CAPACITY :: 128
MAX_OPERATIONS :: 256
MAX_INPUT_VALUES :: 515
MAX_OUTPUT_BYTES :: 4096

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte: int = 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

@(export)
priority_queues :: proc "c" (input: [^]i64, length: c.size_t,
                             output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_INPUT_VALUES) do return -1
    if input[0] < 1 || input[0] > MAX_CAPACITY ||
        input[1] < 0 || input[1] > MAX_OPERATIONS do return -1

    capacity := int(input[0])
    operation_count := int(input[1])
    if int(length) != 2 + 2 * operation_count do return -1
    for operation := 0; operation < operation_count; operation += 1 {
        opcode := input[2 + 2 * operation]
        argument := input[3 + 2 * operation]
        if opcode < 0 || opcode > 5 do return -1
        if opcode == 0 {
            if argument < -2147483648 || argument > 2147483647 do return -1
        } else if argument != 0 do return -1
    }

    if operation_count == 0 do return 0
    needed := operation_count * 16
    if needed > MAX_OUTPUT_BYTES || output == nil ||
        output_capacity < c.size_t(needed) do return -2

    heap: [MAX_CAPACITY + 1]i32
    size := 0
    for operation := 0; operation < operation_count; operation += 1 {
        opcode := input[2 + 2 * operation]
        argument := input[3 + 2 * operation]
        status: i64 = 0
        value: i64 = 0

        if opcode == 0 {
            if size == capacity {
                status = 1
            } else {
                size += 1
                heap[size] = i32(argument)
                index := size
                for index > 1 && heap[index / 2] < heap[index] {
                    temporary := heap[index / 2]
                    heap[index / 2] = heap[index]
                    heap[index] = temporary
                    index /= 2
                }
            }
        } else if opcode == 1 {
            if size == 0 {
                status = 2
            } else {
                value = i64(heap[1])
                heap[1] = heap[size]
                heap[size] = 0
                size -= 1
                index := 1
                for index * 2 <= size {
                    child := index * 2
                    if child < size && heap[child + 1] > heap[child] do child += 1
                    if heap[index] >= heap[child] do break
                    temporary := heap[index]
                    heap[index] = heap[child]
                    heap[child] = temporary
                    index = child
                }
            }
        } else if opcode == 2 {
            if size > 0 do value = i64(heap[1])
        } else if opcode == 3 {
            if size == 0 do value = 1
        } else if opcode == 4 {
            if size == capacity do value = 1
        } else {
            value = i64(size)
        }

        store_i64_le(output, operation * 16, status)
        store_i64_le(output, operation * 16 + 8, value)
    }
    return i64(needed)
}
