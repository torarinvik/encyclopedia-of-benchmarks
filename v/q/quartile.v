module quartile

fn store_i64_le(mut output &u8, offset int, value i64) {
    mut bits := u64(value)
    for byte in 0 .. 8 { unsafe { output[offset + byte] = u8(bits & 255) }; bits >>= 8 }
}

// Sort up to ten bounded values and encode quartile statistics.
@[export: 'quartile']
pub fn quartile(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
    if length < 2 || length > 11 || input[0] < 1 || input[0] > 10 { return -1 }
    count := int(input[0])
    if int(length) != count + 1 { return -1 }
    mut values := [10]i64{}
    for index in 0 .. count {
        if input[index + 1] < 0 || input[index + 1] > 99 { return -1 }
        values[index] = input[index + 1]
    }
    for i in 0 .. count {
        for j in 0 .. count {
            if values[i] < values[j] { temporary := values[i]; values[i] = values[j]; values[j] = temporary }
        }
    }
    q1 := values[count / 4]
    q3 := values[(3 * count) / 4]
    required := (count + 4) * 8
    if output_capacity < usize(required) { return -2 }
    store_i64_le(mut output, 0, i64(count))
    for index in 0 .. count { store_i64_le(mut output, 8 * (index + 1), values[index]) }
    store_i64_le(mut output, 8 * (count + 1), q1)
    store_i64_le(mut output, 8 * (count + 2), q3)
    store_i64_le(mut output, 8 * (count + 3), q3 - q1)
    return i64(required)
}
