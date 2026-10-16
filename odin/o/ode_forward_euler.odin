package ode_forward_euler

import "core:c"

store_f64_le :: proc(output: [^]u8, offset: int, value: f64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
ode_forward_euler :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length != 4 do return -1
    if values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 4 ||
        values[2] < -10 || values[2] > 10 || values[3] < -10 || values[3] > 10 do return -1
    if output == nil || output_capacity < 16 do return -2
    dt := f64(values[1]) / 4.0
    u, v := f64(values[2]), f64(values[3])
    for step := i64(0); step < values[0]; step += 1 {
        old_u, old_v := u, v
        u = old_u + dt * old_v
        v = old_v - dt * old_u
    }
    store_f64_le(output, 0, u)
    store_f64_le(output, 8, v)
    return 16
}
