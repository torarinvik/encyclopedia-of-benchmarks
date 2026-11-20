module blr_linearity_test

const max_input = 130

fn put_word(mut output &u8, offset int, value i64) {
    bits := u64(value)
    for byte in 0 .. 8 {
        unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
    }
}

@[export: 'blr_linearity_test']
pub fn blr_linearity_test(input &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > max_input { return -1 }
        if input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 32 { return -1 }
        n, q := int(input[0]), int(input[1])
        domain := 1 << n
        if length != usize(2 + domain + 2*q) { return -1 }
        table_at, tape_at := 2, 2 + domain
        for i in 0 .. domain {
            if input[table_at+i] != 0 && input[table_at+i] != 1 { return -1 }
        }
        for i in 0 .. 2*q {
            point := input[tape_at+i]
            if point < 0 || point >= i64(domain) { return -1 }
        }
        mut rounds := 0
        mut accepted := i64(1)
        for round in 0 .. q {
            x, y := int(input[tape_at+2*round]), int(input[tape_at+2*round+1])
            rounds++
            if (input[table_at+x] ^ input[table_at+y]) != input[table_at+(x ^ y)] {
                accepted = 0
                break
            }
        }
        if output == nil || capacity < 24 { return -2 }
        mut staged := [24]u8{}
        put_word(mut &staged[0], 0, accepted)
        put_word(mut &staged[0], 8, i64(rounds))
        put_word(mut &staged[0], 16, i64(3*rounds))
        for i in 0 .. 24 { output[i] = staged[i] }
        return 24
    }
}
