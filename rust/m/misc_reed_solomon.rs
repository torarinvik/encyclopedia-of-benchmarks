// Derived from the Reed-Solomon program by Simon Rockliff, 26 June 1991.
// See benchmarks/m/misc_reed_solomon/LICENSE.txt for the complete permission notice.
const MESSAGE_BYTES: usize = 188;
const PARITY_BYTES: usize = 16;
const CODEWORD_BYTES: usize = 204;
const FULL_BYTES: usize = 255;

fn make_tables(alpha: &mut [i32; FULL_BYTES], index_of: &mut [i32; 256]) {
    let polynomial = [1i32, 0, 1, 1, 1, 0, 0, 0];
    index_of.fill(-1);
    let mut mask = 1i32;
    let mut alpha_8 = 0i32;
    for i in 0..8 {
        alpha[i] = mask;
        index_of[alpha[i] as usize] = i as i32;
        if polynomial[i] != 0 { alpha_8 ^= mask; }
        mask <<= 1;
    }
    alpha[8] = alpha_8;
    index_of[alpha_8 as usize] = 8;
    mask >>= 1;
    for i in 9..FULL_BYTES {
        alpha[i] = if alpha[i - 1] >= mask {
            alpha_8 ^ ((alpha[i - 1] ^ mask) << 1)
        } else {
            alpha[i - 1] << 1
        };
        index_of[alpha[i] as usize] = i as i32;
    }
    index_of[0] = -1;
}

fn make_generator(alpha: &[i32; FULL_BYTES], index_of: &[i32; 256], generator: &mut [i32; 17]) {
    generator[0] = 2;
    generator[1] = 1;
    for root in 2..=PARITY_BYTES {
        generator[root] = 1;
        for index in (1..root).rev() {
            generator[index] = if generator[index] != 0 {
                generator[index - 1] ^ alpha[((index_of[generator[index] as usize] + root as i32) % FULL_BYTES as i32) as usize]
            } else {
                generator[index - 1]
            };
        }
        generator[0] = alpha[((index_of[generator[0] as usize] + root as i32) % FULL_BYTES as i32) as usize];
    }
    for index in 0..=PARITY_BYTES { generator[index] = index_of[generator[index] as usize]; }
}

fn encode(values: &[i64], alpha: &[i32; FULL_BYTES], index_of: &[i32; 256],
          generator: &[i32; 17], codeword: &mut [i32; CODEWORD_BYTES]) {
    let mut data = [0i32; 239];
    let mut parity = [0i32; PARITY_BYTES];
    for index in 0..MESSAGE_BYTES { data[51 + index] = values[index] as i32; }
    for data_index in (0..239).rev() {
        let feedback = index_of[(data[data_index] ^ parity[15]) as usize];
        if feedback != -1 {
            for parity_index in (1..PARITY_BYTES).rev() {
                parity[parity_index] = if generator[parity_index] != -1 {
                    parity[parity_index - 1] ^ alpha[((generator[parity_index] + feedback) % FULL_BYTES as i32) as usize]
                } else {
                    parity[parity_index - 1]
                };
            }
            parity[0] = alpha[((generator[0] + feedback) % FULL_BYTES as i32) as usize];
        } else {
            for parity_index in (1..PARITY_BYTES).rev() { parity[parity_index] = parity[parity_index - 1]; }
            parity[0] = 0;
        }
    }
    for index in 0..MESSAGE_BYTES { codeword[index] = values[index] as i32; }
    for index in 0..PARITY_BYTES { codeword[MESSAGE_BYTES + index] = parity[index]; }
}

fn multiply(left: i32, right: i32, alpha: &[i32; FULL_BYTES], index_of: &[i32; 256]) -> i32 {
    if left == 0 || right == 0 { return 0; }
    let mut exponent = index_of[left as usize] + index_of[right as usize];
    if exponent >= FULL_BYTES as i32 { exponent -= FULL_BYTES as i32; }
    alpha[exponent as usize]
}

fn divide(left: i32, right: i32, alpha: &[i32; FULL_BYTES], index_of: &[i32; 256]) -> i32 {
    if left == 0 { return 0; }
    let mut exponent = index_of[left as usize] - index_of[right as usize];
    if exponent < 0 { exponent += FULL_BYTES as i32; }
    alpha[exponent as usize]
}

fn correct_one(codeword: &mut [i32; CODEWORD_BYTES], expected_position: i32,
               alpha: &[i32; FULL_BYTES], index_of: &[i32; 256]) -> bool {
    let mut syndrome_1 = 0i32;
    let mut syndrome_2 = 0i32;
    for full_position in 0..FULL_BYTES {
        let symbol = if full_position < PARITY_BYTES {
            codeword[MESSAGE_BYTES + full_position]
        } else if full_position >= 67 {
            codeword[full_position - 67]
        } else {
            0
        };
        syndrome_1 ^= multiply(symbol, alpha[full_position % FULL_BYTES], alpha, index_of);
        syndrome_2 ^= multiply(symbol, alpha[(2 * full_position) % FULL_BYTES], alpha, index_of);
    }
    if syndrome_1 == 0 && syndrome_2 == 0 { return true; }
    if syndrome_1 == 0 { return false; }
    let location = divide(syndrome_2, syndrome_1, alpha, index_of);
    let Some(full_position) = (0..FULL_BYTES).find(|&index| alpha[index] == location) else { return false; };
    let transmitted_position = if full_position < PARITY_BYTES {
        MESSAGE_BYTES + full_position
    } else if full_position >= 67 {
        full_position - 67
    } else {
        return false;
    };
    if transmitted_position as i32 != expected_position { return false; }
    let magnitude = divide(syndrome_1, alpha[full_position], alpha, index_of);
    codeword[transmitted_position] ^= magnitude;
    true
}

#[no_mangle]
pub unsafe extern "C" fn misc_reed_solomon(values: *const i64, length: usize,
                                             output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || (length != MESSAGE_BYTES + 1 && length != MESSAGE_BYTES + 3) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if values[..MESSAGE_BYTES].iter().any(|&value| !(0..=255).contains(&value)) { return -1; }
    let error_count = values[MESSAGE_BYTES];
    if (error_count == 0 && length != MESSAGE_BYTES + 1) ||
       (error_count == 1 && length != MESSAGE_BYTES + 3) ||
       (error_count != 0 && error_count != 1) { return -1; }
    let mut error_position = -1i32;
    if error_count == 1 {
        if values[189] < 0 || values[189] >= CODEWORD_BYTES as i64 || values[190] < 0 || values[190] > 255 { return -1; }
        error_position = values[189] as i32;
    }
    if output.is_null() || output_capacity < CODEWORD_BYTES { return -2; }

    let mut alpha = [0i32; FULL_BYTES];
    let mut index_of = [0i32; 256];
    let mut generator = [0i32; PARITY_BYTES + 1];
    let mut staged = [0i32; CODEWORD_BYTES];
    make_tables(&mut alpha, &mut index_of);
    make_generator(&alpha, &index_of, &mut generator);
    encode(values, &alpha, &index_of, &generator, &mut staged);
    if error_count == 1 { staged[error_position as usize] = values[190] as i32; }
    if !correct_one(&mut staged, error_position, &alpha, &index_of) { return -1; }
    for index in 0..CODEWORD_BYTES { *output.add(index) = staged[index] as u8; }
    CODEWORD_BYTES as i64
}
