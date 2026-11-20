package bitset_xor_shift_trace

import "core:c"

MAX_WORDS :: 64
MAX_OPERATIONS :: 64

popcount64 :: proc(value: u64) -> i32 {
    remaining := value
    count: i32 = 0
    for remaining != 0 { remaining &= remaining - 1; count += 1 }
    return count
}

put32 :: proc(output: [^]u8, offset: int, value: i32) {
    bits := transmute(u32)value
    for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
bitset_xor_shift_trace :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 131 do return -1
    n64, q64 := input[0], input[1]
    if n64 < 1 || n64 > 4096 || q64 < 0 || q64 > 64 do return -1
    n, q := int(n64), int(q64)
    word_count := (n + 63) / 64
    shift_offset := 2 + word_count
    if length != c.size_t(shift_offset + q) do return -1

    words: [MAX_WORDS]u64
    for word := 0; word < word_count; word += 1 { words[word] = transmute(u64)input[2+word] }
    tail_bits := n % 64
    tail_mask := if tail_bits == 0 { u64(0)-1 } else { (u64(1) << tail_bits)-1 }
    if (words[word_count-1] & ~tail_mask) != 0 do return -1
    for operation := 0; operation < q; operation += 1 {
        shift := input[shift_offset+operation]
        if shift < -(n64-1) || shift > n64-1 do return -1
    }

    output_bytes := q * 4
    if output_bytes > 0 && (output == nil || capacity < c.size_t(output_bytes)) do return -2
    counts: [MAX_OPERATIONS]i32 = {}
    for operation := 0; operation < q; operation += 1 {
        shift := input[shift_offset+operation]
        if shift == 0 {
            for word := 0; word < word_count; word += 1 { words[word] = 0 }
        } else if shift > 0 {
            distance := int(shift); whole, part := distance/64, distance%64
            for destination := 0; destination < word_count; destination += 1 {
                source := destination + whole
                shifted: u64 = 0
                if source < word_count { shifted = words[source] >> part }
                if part != 0 && source+1 < word_count { shifted |= words[source+1] << (64-part) }
                words[destination] ^= shifted
            }
        } else {
            distance := int(-shift); whole, part := distance/64, distance%64
            for reverse_index := 0; reverse_index < word_count; reverse_index += 1 {
                destination := word_count-1-reverse_index
                source := destination-whole
                shifted: u64 = 0
                if source >= 0 { shifted = words[source] << part }
                if part != 0 && source > 0 { shifted |= words[source-1] >> (64-part) }
                words[destination] ^= shifted
            }
        }
        words[word_count-1] &= tail_mask
        for word := 0; word < word_count; word += 1 { counts[operation] += popcount64(words[word]) }
    }
    for operation := 0; operation < q; operation += 1 { put32(output, operation*4, counts[operation]) }
    return i64(output_bytes)
}
