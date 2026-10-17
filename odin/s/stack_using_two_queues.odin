package stack_using_two_queues

import "core:c"

@(export)
stack_using_two_queues :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 257 do return -1
    if input[0] < 0 || input[0] > 128 || length != c.size_t(1 + 2 * input[0]) do return -1
    queue_a: [128]i64
    queue_b: [128]i64
    tags: [128]i64
    results: [128]i64
    main_q: [^]i64 = &queue_a[0]
    temp_q: [^]i64 = &queue_b[0]
    head, tail, record_count, pos: c.size_t = 0, 0, 0, 1
    for opi: c.size_t = 0; opi < c.size_t(input[0]); opi += 1 {
        opcode, operand := input[pos], input[pos+1]
        pos += 2
        if opcode == 0 {
            if operand < -2_147_483_648 || operand > 2_147_483_647 do return -1
            temp_tail: c.size_t = 0
            temp_q[temp_tail] = operand
            temp_tail += 1
            for head < tail {
                temp_q[temp_tail] = main_q[head]
                temp_tail += 1
                head += 1
            }
            main_q, temp_q = temp_q, main_q
            head, tail = 0, temp_tail
        } else if opcode == 1 {
            if operand != 0 || head == tail do return -1
            tags[record_count] = 0
            results[record_count] = main_q[head]
            record_count += 1
            head += 1
        } else if opcode == 2 {
            if operand != 0 do return -1
            if head == tail { tags[record_count], results[record_count] = 1, 0 }
            else { tags[record_count], results[record_count] = 0, main_q[head] }
            record_count += 1
        } else do return -1
    }
    bytes := record_count * 16
    if output == nil || output_capacity < bytes do return -2
    for i: c.size_t = 0; i < record_count; i += 1 {
        tag_bits, value_bits := u64(tags[i]), u64(results[i])
        for b: c.size_t = 0; b < 8; b += 1 {
            output[16*i+b] = u8(tag_bits >> (8*b))
            output[16*i+8+b] = u8(value_bits >> (8*b))
        }
    }
    return i64(bytes)
}
