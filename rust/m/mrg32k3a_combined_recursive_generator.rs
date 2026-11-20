const M1: i64 = 4_294_967_087;
const M2: i64 = 4_294_944_443;

fn residue(value: i64, modulus: i64) -> i64 {
    let result = value % modulus;
    if result < 0 { result + modulus } else { result }
}

fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn mrg32k3a_combined_recursive_generator(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 7 { return -1; }
    let mut x1 = [0i64; 3];
    let mut x2 = [0i64; 3];
    for index in 0..3 {
        x1[index] = unsafe { *input.add(index) };
        x2[index] = unsafe { *input.add(index + 3) };
        if x1[index] < 0 || x1[index] >= M1 { return -1; }
        if x2[index] < 0 || x2[index] >= M2 { return -1; }
    }
    if (x1[0] | x1[1] | x1[2]) == 0 || (x2[0] | x2[1] | x2[2]) == 0 { return -1; }
    let count_value = unsafe { *input.add(6) };
    if count_value < 0 || count_value > 64 { return -1; }

    let count = count_value as usize;
    let required = count * 8;
    if capacity < required || (required != 0 && output.is_null()) { return -2; }
    if count == 0 { return 0; }

    for step in 0..count {
        let next1 = residue(1_403_580 * x1[1] - 810_728 * x1[0], M1);
        let next2 = residue(527_612 * x2[2] - 1_370_589 * x2[0], M2);
        x1 = [x1[1], x1[2], next1];
        x2 = [x2[1], x2[2], next2];
        let mut z = next1 - next2;
        if z < 0 { z += M1; }
        put_i64_le(output, step * 8, z);
    }
    required as i64
}
