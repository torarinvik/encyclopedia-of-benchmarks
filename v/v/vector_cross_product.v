module vector_cross_product

import math

fn store_i64_le(mut output &u8, offset int, value i64) {
    mut bits := u64(value)
    for byte in 0 .. 8 {
        unsafe { output[offset + byte] = u8(bits & 255) }
        bits >>= 8
    }
}

// Cross two bounded integer vectors and encode components plus magnitude.
@[export: 'vector_cross_product']
pub fn vector_cross_product(input &i64, input_length usize, mut output &u8,
        output_capacity usize) i64 {
    if input_length != 6 { return -1 }
    for index in 0 .. 6 {
        if input[index] < -1_000_000 || input[index] > 1_000_000 { return -1 }
    }
    x := input[1] * input[5] - input[2] * input[4]
    y := -((input[0] * input[5]) - (input[2] * input[3]))
    z := input[0] * input[4] - input[1] * input[3]
    magnitude := math.sqrt(f64(x) * f64(x) + f64(y) * f64(y) + f64(z) * f64(z))
    magnitude_micro := i64(magnitude * 1_000_000.0 + 0.5)
    if output_capacity < 32 { return -2 }
    store_i64_le(mut output, 0, x); store_i64_le(mut output, 8, y)
    store_i64_le(mut output, 16, z); store_i64_le(mut output, 24, magnitude_micro)
    return 32
}
