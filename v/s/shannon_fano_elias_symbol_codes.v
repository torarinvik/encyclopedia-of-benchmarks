@[export: 'shannon_fano_elias_symbol_codes']
pub fn shannon_fano_elias_symbol_codes(input &i64, length usize, output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 2 || length > 10 { return -1 }
    raw_n := unsafe { input[0] }
    if raw_n < 1 || raw_n > 8 || length != usize(raw_n + 1) { return -1 }
    n := int(raw_n)
    mut total := i64(0)
    for i in 0 .. n {
        weight := unsafe { input[1+i] }
        if weight < 1 || weight > 15 { return -1 }
        total += weight
    }
    if total > 120 { return -1 }

    mut staged := [17]u8{}
    staged[0] = u8(n)
    mut prefix := i64(0)
    for i in 0 .. n {
        weight := unsafe { input[1+i] }
        mut bits := 1
        for (i64(1) << (bits-1))*weight < total { bits++ }
        numerator := (2*prefix + weight) * (i64(1) << (bits-1))
        code := u8(numerator / total)
        staged[1+2*i] = u8(bits)
        staged[2+2*i] = code << u8(8-bits)
        prefix += weight
    }
    needed := 1 + 2*n
    if unsafe { output == nil } || capacity < usize(needed) { return -2 }
    for i in 0 .. needed { unsafe { output[i] = staged[i] } }
    return i64(needed)
}
