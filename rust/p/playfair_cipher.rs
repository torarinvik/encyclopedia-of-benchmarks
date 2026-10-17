const MIN_PARSEABLE_INPUT_LENGTH: usize = 3;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 157;
const MAX_KEY_LENGTH: usize = 25;
const MAX_TEXT_LENGTH: usize = 128;
const FNV_OFFSET_BASIS: u64 = 14_695_981_039_346_656_037;
const FNV_PRIME: u64 = 1_099_511_628_211;
const LOW63_MASK: u64 = 0x7fff_ffff_ffff_ffff;
const ALPHABET: &[u8; 25] = b"ABCDEFGHIKLMNOPQRSTUVWXYZ";

#[no_mangle]
pub unsafe extern "C" fn playfair_cipher(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(MIN_PARSEABLE_INPUT_LENGTH..=MAX_PARSEABLE_INPUT_LENGTH).contains(&length) {
        return -1;
    }

    let operation = *input;
    let key_length_value = *input.add(1);
    if !(0..=1).contains(&operation) || !(0..=MAX_KEY_LENGTH as i64).contains(&key_length_value) {
        return -1;
    }
    let key_length = key_length_value as usize;
    let text_length_index = 2 + key_length;
    if length <= text_length_index {
        return -1;
    }
    let text_length_value = *input.add(text_length_index);
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&text_length_value) || text_length_value % 2 != 0 {
        return -1;
    }
    let text_length = text_length_value as usize;
    let text_start = text_length_index + 1;
    if length != text_start + text_length {
        return -1;
    }

    let mut seen = [false; 26];
    let mut square = [0_u8; 25];
    let mut square_length = 0_usize;
    for index in 0..key_length {
        let value = *input.add(2 + index);
        if !(65..=90).contains(&value) || value == 74 {
            return -1;
        }
        let letter = value as u8;
        let slot = (letter - b'A') as usize;
        if !seen[slot] {
            seen[slot] = true;
            square[square_length] = letter;
            square_length += 1;
        }
    }
    for &letter in ALPHABET {
        let slot = (letter - b'A') as usize;
        if !seen[slot] {
            seen[slot] = true;
            square[square_length] = letter;
            square_length += 1;
        }
    }

    let mut positions = [0_u8; 26];
    for (index, &letter) in square.iter().enumerate() {
        positions[(letter - b'A') as usize] = index as u8;
    }

    let mut previous = 0_u8;
    for index in 0..text_length {
        let value = *input.add(text_start + index);
        if !(65..=90).contains(&value) || value == 74 {
            return -1;
        }
        let letter = value as u8;
        if operation == 0 && index > 0 && letter == previous {
            return -1;
        }
        previous = letter;
    }

    let mut hash = FNV_OFFSET_BASIS;
    let shift = if operation == 0 { 1_i32 } else { -1_i32 };
    for index in (0..text_length).step_by(2) {
        let first = *input.add(text_start + index) as u8;
        let second = *input.add(text_start + index + 1) as u8;
        let position1 = positions[(first - b'A') as usize] as usize;
        let position2 = positions[(second - b'A') as usize] as usize;
        let row1 = position1 / 5;
        let column1 = position1 % 5;
        let row2 = position2 / 5;
        let column2 = position2 % 5;
        let (result1, result2) = if row1 == row2 {
            let next1 = (column1 as i32 + shift + 5) % 5;
            let next2 = (column2 as i32 + shift + 5) % 5;
            (square[row1 * 5 + next1 as usize], square[row2 * 5 + next2 as usize])
        } else if column1 == column2 {
            let next1 = (row1 as i32 + shift + 5) % 5;
            let next2 = (row2 as i32 + shift + 5) % 5;
            (square[next1 as usize * 5 + column1], square[next2 as usize * 5 + column2])
        } else {
            (square[row1 * 5 + column2], square[row2 * 5 + column1])
        };
        hash = (hash ^ result1 as u64).wrapping_mul(FNV_PRIME);
        hash = (hash ^ result2 as u64).wrapping_mul(FNV_PRIME);
    }
    (hash & LOW63_MASK) as i64
}
