package queue

import "core:c"

// Bounded ring-buffer queue with a deterministic operation-trace checksum.
@(export)
queue_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 1024 || length % 2 != 0 do return -1
    operation_count := length / 2
    data_queue: [256]i64
    head: c.size_t = 0
    count: c.size_t = 0
    checksum: i64 = 0
    for operation := c.size_t(0); operation < operation_count; operation += 1 {
        opcode := values[2 * operation]
        payload := values[2 * operation + 1]
        observed: i64 = 0
        returns_value := true
        if opcode == 0 {
            if payload < -1000000 || payload > 1000000 || count == 256 do return -1
            data_queue[(head + count) % 256] = payload
            count += 1
            returns_value = false
        } else if opcode == 1 {
            if payload != 0 || count == 0 do return -1
            observed = data_queue[head]
            head = (head + 1) % 256
            count -= 1
        } else if opcode == 2 {
            if payload != 0 || count == 0 do return -1
            observed = data_queue[head]
        } else if opcode == 3 {
            if payload != 0 || count == 0 do return -1
            observed = data_queue[(head + count - 1) % 256]
        } else if opcode == 4 {
            if payload != 0 do return -1
            observed = i64(count == 0)
        } else if opcode == 5 {
            if payload != 0 do return -1
            observed = i64(count)
        } else {
            return -1
        }
        if returns_value do checksum += i64(operation + 1) * (observed + 1000000)
    }
    for index := c.size_t(0); index < count; index += 1 {
        checksum += i64(operation_count + index + 1) * (data_queue[(head + index) % 256] + 1000000)
    }
    return checksum
}
