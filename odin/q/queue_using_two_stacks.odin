package queue_using_two_stacks

import "core:c"

// Amortized FIFO queue implemented with an input and an output stack.
@(export)
queue_using_two_stacks_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 1024 || length % 2 != 0 do return -1
    operation_count := length / 2
    in_stack: [256]i64
    out_stack: [256]i64
    in_count: c.size_t = 0
    out_count: c.size_t = 0
    checksum: i64 = 0
    for operation := c.size_t(0); operation < operation_count; operation += 1 {
        opcode := values[2 * operation]
        payload := values[2 * operation + 1]
        observed: i64 = 0
        returns_value := true
        if opcode == 0 {
            if payload < -1000000 || payload > 1000000 || in_count + out_count == 256 do return -1
            in_stack[in_count] = payload
            in_count += 1
            returns_value = false
        } else if opcode == 1 || opcode == 2 {
            if payload != 0 do return -1
            if out_count == 0 {
                for in_count > 0 {
                    in_count -= 1
                    out_stack[out_count] = in_stack[in_count]
                    out_count += 1
                }
            }
            if out_count == 0 do return -1
            if opcode == 1 {
                out_count -= 1
                observed = out_stack[out_count]
            } else {
                observed = out_stack[out_count - 1]
            }
        } else if opcode == 3 {
            if payload != 0 do return -1
            observed = i64(in_count + out_count == 0)
        } else if opcode == 4 {
            if payload != 0 do return -1
            observed = i64(in_count + out_count)
        } else {
            return -1
        }
        if returns_value do checksum += i64(operation + 1) * (observed + 1000000)
    }
    for index := c.size_t(0); index < out_count; index += 1 {
        checksum += i64(operation_count + index + 1) * (out_stack[out_count - index - 1] + 1000000)
    }
    for index := c.size_t(0); index < in_count; index += 1 {
        checksum += i64(operation_count + out_count + index + 1) * (in_stack[index] + 1000000)
    }
    return checksum
}
