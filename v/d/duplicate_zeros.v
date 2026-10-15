module duplicate_zeros

fn write_i32(output &u8, position usize, value i64) {
    encoded := if value < 0 { value + 4294967296 } else { value }
    unsafe {
        output[position] = u8(encoded % 256)
        output[position + 1] = u8((encoded / 256) % 256)
        output[position + 2] = u8((encoded / 65536) % 256)
        output[position + 3] = u8(encoded / 16777216)
    }
}

@[export: 'duplicate_zeros']
pub fn duplicate_zeros(values &i64, length usize, output &u8, output_capacity usize) i64 {
    if length > 64 { return -1 }
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value < 0 || value > 1000 { return -1 }
    }
    required := 4 * length
    if output_capacity < required { return -2 }
    mut source := usize(0)
    mut destination := usize(0)
    for destination < length {
        value := unsafe { values[source] }
        source++
        write_i32(output, usize(4) * destination, value)
        destination++
        if value == 0 && destination < length {
            write_i32(output, usize(4) * destination, 0)
            destination++
        }
    }
    return i64(length)
}
