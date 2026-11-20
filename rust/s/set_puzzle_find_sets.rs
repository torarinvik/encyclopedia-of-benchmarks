const MAX_CARDS: usize = 12;
const MAX_INPUT_WORDS: usize = 14;
const DECK_SIZE: usize = 81;

fn complement_code(a: i8, b: i8) -> usize {
    let (a, b) = (a as usize, b as usize);
    let mut result = 0usize;
    let mut place = 1usize;
    for _ in 0..4 {
        let digit_sum = (a / place) % 3 + (b / place) % 3;
        result += ((3 - digit_sum % 3) % 3) * place;
        place *= 3;
    }
    result
}

unsafe fn write_word(output: *mut u8, word: usize, value: i64) {
    let bits = value as u64;
    for offset in 0..8 {
        unsafe { output.add(word * 8 + offset).write((bits >> (offset * 8)) as u8); }
    }
}

#[no_mangle]
pub unsafe extern "C" fn set_puzzle_find_sets(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_WORDS).contains(&length) { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let raw_count = values[0];
    if !(0..=MAX_CARDS as i64).contains(&raw_count) || length != raw_count as usize + 1 {
        return -1;
    }

    let mut index_by_code = [-1i8; DECK_SIZE];
    let mut code_by_index = [0i8; MAX_CARDS];
    let count = raw_count as usize;
    for i in 0..count {
        let code = values[i + 1];
        if !(0..DECK_SIZE as i64).contains(&code) || index_by_code[code as usize] >= 0 {
            return -1;
        }
        index_by_code[code as usize] = i as i8;
        code_by_index[i] = code as i8;
    }

    let mut set_count = 0usize;
    for i in 0..count {
        for j in i + 1..count {
            let k = index_by_code[complement_code(code_by_index[i], code_by_index[j])];
            if k > j as i8 { set_count += 1; }
        }
    }
    let output_bytes = (1 + 3 * set_count) * 8;
    if output.is_null() || capacity < output_bytes { return -2; }

    unsafe { write_word(output, 0, set_count as i64); }
    let mut word = 1usize;
    for i in 0..count {
        for j in i + 1..count {
            let k = index_by_code[complement_code(code_by_index[i], code_by_index[j])];
            if k > j as i8 {
                unsafe {
                    write_word(output, word, i as i64);
                    write_word(output, word + 1, j as i64);
                    write_word(output, word + 2, k as i64);
                }
                word += 3;
            }
        }
    }
    output_bytes as i64
}
