const MAX_TEAMS: usize = 8;
const MAX_PARSEABLE_INPUT: usize = 2;
const MAX_CELLS: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn round_robin_tournament_schedule(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length == 0 || length > MAX_PARSEABLE_INPUT {
        return -1;
    }
    if length != 1 {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input_ptr, length) };
    let n_word = input[0];
    if n_word < 2 || n_word > MAX_TEAMS as i64 {
        return -1;
    }

    let n = n_word as usize;
    let padded = n + (n & 1);
    let ring_size = padded - 1;
    let rounds = ring_size;
    let fixed = padded - 1;
    let mut table = [u8::MAX; MAX_CELLS];
    for round in 0..rounds {
        if fixed < n {
            table[fixed * rounds + round] = round as u8;
            table[round * rounds + round] = fixed as u8;
        }
        for offset in 1..(padded / 2) {
            let left = (round + offset) % ring_size;
            let right = (round + ring_size - offset) % ring_size;
            if left < n && right < n {
                table[left * rounds + round] = right as u8;
                table[right * rounds + round] = left as u8;
            }
        }
    }

    let required = 2 + n * rounds;
    if output_ptr.is_null() || capacity < required {
        return -2;
    }
    let output = unsafe { std::slice::from_raw_parts_mut(output_ptr, required) };
    output[0] = n as u8;
    output[1] = rounds as u8;
    output[2..required].copy_from_slice(&table[..n * rounds]);
    required as i64
}
