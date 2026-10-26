module ring_exact_covering_protocol

const scale = i64(16)
const max_n = 12
const max_steps = 64
const max_input = 79
const max_output = 208

fn put_i64(mut output &u8, offset int, value i64) {
    bits := u64(value)
    for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'ring_exact_covering_protocol']
pub fn ring_exact_covering_protocol(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if input == nil || length < 3 || length > max_input { return -1 }
    if unsafe { input[0] } < 2 || unsafe { input[0] } > max_n || unsafe { input[2] } < 0 || unsafe { input[2] } > max_steps { return -1 }
    n := int(unsafe { input[0] }); steps := int(unsafe { input[2] })
    if length != usize(3 + n + steps) { return -1 }
    circumference := scale * i64(n); visibility := unsafe { input[1] }
    if visibility < 2 * scale || visibility > circumference { return -1 }
    mut position := [max_n]i64{}
    for i in 0 .. n {
        position[i] = unsafe { input[3 + i] }
        if position[i] < 0 || position[i] >= circumference || (i > 0 && position[i - 1] >= position[i]) { return -1 }
    }
    for j in 0 .. steps {
        activation := unsafe { input[3 + n + j] }
        if activation < 0 || activation >= i64(n) { return -1 }
    }
    mut moved := i64(0)
    for j in 0 .. steps {
        sensor := int(unsafe { input[3 + n + j] }); next := (sensor + 1) % n
        gap := (position[next] - position[sensor] + circumference) % circumference
        mut distance := i64(0)
        if gap > visibility { distance = scale } else if gap > scale { distance = gap - scale }
        if distance != 0 { position[sensor] = (position[sensor] + distance) % circumference; moved++ }
    }
    bytes := 8 * (2 + 2 * n)
    if output == nil || capacity < usize(bytes) { return -2 }
    mut staged := [max_output]u8{}
    put_i64(mut &staged[0], 0, i64(n)); put_i64(mut &staged[0], 8, moved)
    for i in 0 .. n { put_i64(mut &staged[0], 8 * (2 + i), position[i]) }
    for i in 0 .. n {
        gap := (position[(i + 1) % n] - position[i] + circumference) % circumference
        put_i64(mut &staged[0], 8 * (2 + n + i), gap)
    }
    unsafe { for i in 0 .. bytes { output[i] = staged[i] } }
    return i64(bytes)
}
