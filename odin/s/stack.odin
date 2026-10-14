package stack

import "core:c"

// Bounded array-backed integer stack with a deterministic operation-trace checksum.
@(export)
stack_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 1024 || length % 2 != 0 do return -1
    operation_count := length / 2
    data_stack: [256]i64
    top: c.size_t = 0
    checksum: i64 = 0
    for operation := c.size_t(0); operation < operation_count; operation += 1 {
        opcode := values[2 * operation]
        payload := values[2 * operation + 1]
        observed: i64 = 0
        returns_value := true
        if opcode == 0 {
            if payload < -1000000 || payload > 1000000 || top == 256 do return -1
            data_stack[top] = payload
            top += 1
            returns_value = false
        } else if opcode == 1 {
            if payload != 0 || top == 0 do return -1
            top -= 1
            observed = data_stack[top]
        } else if opcode == 2 {
            if payload != 0 || top == 0 do return -1
            observed = data_stack[top - 1]
        } else if opcode == 3 {
            if payload != 0 do return -1
            if top == 0 do observed = 1
        } else {
            return -1
        }
        if returns_value do checksum += i64(operation + 1) * (observed + 1000000)
    }
    for index := c.size_t(0); index < top; index += 1 {
        checksum += i64(operation_count + index + 1) * (data_stack[index] + 1000000)
    }
    return checksum
}
