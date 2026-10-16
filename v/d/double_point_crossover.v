module double_point_crossover

fn put_i64_le(mut output &u8, offset int, value i64) {
    bits := u64(value)
    for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'double_point_crossover']
pub fn double_point_crossover(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if length < 7 || length > 131 { return -1 }
    n := unsafe { input[0] }; j1 := unsafe { input[1] }; j2 := unsafe { input[2] }
    if n < 2 || n > 64 || length != usize(3 + 2 * n) || j1 < 1 || j1 >= j2 || j2 > n { return -1 }
    for i in 0 .. int(2 * n) { if unsafe { input[i + 3] } < -2147483648 || unsafe { input[i + 3] } > 2147483647 { return -1 } }
    count := int(n); bytes := count * 16
    if capacity < usize(bytes) { return -2 }
    for i in 0 .. count {
        mut child1 := unsafe { input[i + 3] }; mut child2 := unsafe { input[count + i + 3] }
        if i >= int(j1) && i < int(j2) { child1, child2 = child2, child1 }
        put_i64_le(mut output, i * 8, child1); put_i64_le(mut output, (count + i) * 8, child2)
    }
    return i64(bytes)
}
