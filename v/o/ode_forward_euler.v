module main

import math

fn store_f64_le(mut output &u8, offset int, value f64) {
    mut bits := math.bits_from_f64(value)
    for byte in 0 .. 8 {
        unsafe { output[offset + byte] = u8(bits & 255) }
        bits >>= 8
    }
}

@[export: 'ode_forward_euler']
pub fn ode_forward_euler(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
    if unsafe { values == nil } || length != 4 { return -1 }
    if values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 4 ||
        values[2] < -10 || values[2] > 10 || values[3] < -10 || values[3] > 10 { return -1 }
    if unsafe { output == nil } || output_capacity < 16 { return -2 }
    dt := f64(values[1]) / 4.0
    mut u := f64(values[2])
    mut v := f64(values[3])
    for _ in 0 .. int(values[0]) {
        old_u, old_v := u, v
        u = old_u + dt * old_v
        v = old_v - dt * old_u
    }
    store_f64_le(mut output, 0, u)
    store_f64_le(mut output, 8, v)
    return 16
}
