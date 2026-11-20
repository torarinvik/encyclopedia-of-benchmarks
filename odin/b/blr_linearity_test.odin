package blr_linearity_test
import "core:c"

MAX_INPUT :: 130
MAX_OUTPUT :: 24

put_word :: proc(out: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { out[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export)
blr_linearity_test :: proc "c" (input: [^]i64, length: c.size_t,
                                  output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT { return -1 }
    if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 32 { return -1 }
    n, q := int(input[0]), int(input[1])
    domain := 1 << n
    if length != c.size_t(2 + domain + 2*q) { return -1 }
    table_at, tape_at := 2, 2 + domain
    for i := 0; i < domain; i += 1 {
        if input[table_at+i] != 0 && input[table_at+i] != 1 { return -1 }
    }
    for i := 0; i < 2*q; i += 1 {
        point := input[tape_at+i]
        if point < 0 || point >= i64(domain) { return -1 }
    }
    rounds, accepted := 0, i64(1)
    for round := 0; round < q; round += 1 {
        x, y := int(input[tape_at+2*round]), int(input[tape_at+2*round+1])
        rounds += 1
        if (input[table_at+x] ^ input[table_at+y]) != input[table_at+(x ^ y)] {
            accepted = 0
            break
        }
    }
    if output == nil || capacity < MAX_OUTPUT { return -2 }
    staged: [MAX_OUTPUT]u8
    put_word(&staged[0], 0, accepted)
    put_word(&staged[0], 8, i64(rounds))
    put_word(&staged[0], 16, i64(3*rounds))
    for i := 0; i < MAX_OUTPUT; i += 1 { output[i] = staged[i] }
    return MAX_OUTPUT
}
