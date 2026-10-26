module three_dimensional_moment_curve
const max_output = 1544

fn put_i64(mut output &u8, offset int, value i64) {
    bits := u64(value)
    for byte in 0..8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'three_dimensional_moment_curve']
pub fn three_dimensional_moment_curve(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if input == nil || length != 1 || unsafe { input[0] } < 0 || unsafe { input[0] } > 64 { return -1 }
    n := int(unsafe { input[0] }); bytes := 8 * (1 + 3 * n)
    if output == nil || capacity < usize(bytes) { return -2 }
    mut staged := [max_output]u8{}
    put_i64(mut &staged[0], 0, i64(n))
    for i in 1 .. n + 1 {
        x := i64(i); offset := 8 * (1 + 3 * (i - 1))
        put_i64(mut &staged[0], offset, x); put_i64(mut &staged[0], offset + 8, x * x); put_i64(mut &staged[0], offset + 16, x * x * x)
    }
    unsafe { for i in 0 .. bytes { output[i] = staged[i] } }
    return i64(bytes)
}
