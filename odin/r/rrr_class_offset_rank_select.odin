package rrr_class_offset_rank_select

import "core:c"

popcount_byte :: proc "contextless" (value: u64) -> int {
    count := 0
    for bit := 0; bit < 8; bit += 1 { count += int((value >> u64(bit)) & 1) }
    return count
}

decode :: proc "contextless" (cls, offset: int) -> u64 {
    remaining := offset
    for candidate := 0; candidate < 256; candidate += 1 {
        if popcount_byte(u64(candidate)) == cls {
            if remaining == 0 { return u64(candidate) }
            remaining -= 1
        }
    }
    return 0
}

@(export)
rrr_class_offset_rank_select :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 35 || input[0] < 1 || input[0] > 63 || input[1] < 0 || input[2] < 0 || input[2] > 16 { return -1 }
    n, q := int(input[0]), int(input[2])
    bits := u64(input[1])
    if bits >> u64(n) != 0 || int(length) != 3+2*q { return -1 }
    for i := 0; i < q; i += 1 {
        op, index := input[3+2*i], input[4+2*i]
        if (op != 0 && op != 1) || index < 1 || (op == 0 && index > i64(n)) || (op == 1 && index > 64) { return -1 }
    }
    if output == nil || capacity < c.size_t(8*q) { return -2 }
    classes, offsets: [8]int
    prefix: [9]int
    blocks := (n+7)/8
    for block := 0; block < blocks; block += 1 {
        byte := (bits >> u64(8*block)) & 255
        classes[block] = popcount_byte(byte)
        for candidate := 0; candidate < int(byte); candidate += 1 {
            if popcount_byte(u64(candidate)) == classes[block] { offsets[block] += 1 }
        }
        prefix[block+1] = prefix[block]+classes[block]
    }
    for i := 0; i < q; i += 1 {
        op, index := input[3+2*i], int(input[4+2*i])
        answer: i64 = -1
        if op == 0 {
            block := (index-1)/8
            byte := decode(classes[block], offsets[block])
            answer = i64(prefix[block])
            for bit := 0; bit < index-8*block; bit += 1 { answer += i64((byte >> u64(bit)) & 1) }
        } else {
            block := 0
            for block < blocks && prefix[block+1] < index { block += 1 }
            if block < blocks {
                remaining := index-prefix[block]
                byte := decode(classes[block], offsets[block])
                for bit := 0; bit < 8 && 8*block+bit < n; bit += 1 {
                    if (byte >> u64(bit)) & 1 != 0 {
                        remaining -= 1
                        if remaining == 0 { answer = i64(8*block+bit+1); break }
                    }
                }
            }
        }
        encoded := u64(answer)
        for byte := 0; byte < 8; byte += 1 { output[8*i+byte] = u8(encoded & 255); encoded >>= 8 }
    }
    return i64(8*q)
}
