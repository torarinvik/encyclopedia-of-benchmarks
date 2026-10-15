const MAX_DIMENSION: usize = 32;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const MAX_WORDS: usize = 96;
const MAX_WORD_LENGTH: usize = 32;
const MAX_INPUT_VALUES: usize = 4096;
const RNG_MODULUS: u64 = 2_147_483_647;

fn next_random(state: &mut u64) -> u64 {
    *state = (*state * 48_271) % RNG_MODULUS;
    *state
}

fn shuffle(items: &mut [usize], state: &mut u64) {
    for remaining in (2..=items.len()).rev() {
        let other = (next_random(state) % remaining as u64) as usize;
        items.swap(remaining - 1, other);
    }
}

fn is_ascii_letter(value: i64) -> bool {
    (65..=90).contains(&value) || (97..=122).contains(&value)
}

#[no_mangle]
pub unsafe extern "C" fn word_search_generator(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 4 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let width_value = *values;
    let height_value = *values.add(1);
    let seed_value = *values.add(2);
    let word_count_value = *values.add(3);
    if !(1..=MAX_DIMENSION as i64).contains(&width_value)
        || !(1..=MAX_DIMENSION as i64).contains(&height_value)
        || !(1..RNG_MODULUS as i64).contains(&seed_value)
        || !(0..=MAX_WORDS as i64).contains(&word_count_value)
    {
        return -1;
    }
    let width = width_value as usize;
    let height = height_value as usize;
    let word_count = word_count_value as usize;

    let mut position = 4usize;
    for _ in 0..word_count {
        if position >= length {
            return -1;
        }
        let word_length_value = *values.add(position);
        position += 1;
        if !(1..=MAX_WORD_LENGTH as i64).contains(&word_length_value)
            || word_length_value as usize > length - position
        {
            return -1;
        }
        let word_length = word_length_value as usize;
        for offset in 0..word_length {
            if !is_ascii_letter(*values.add(position + offset)) {
                return -1;
            }
        }
        position += word_length;
    }
    if position != length {
        return -1;
    }

    let cells = width * height;
    if output.is_null() || output_capacity < cells {
        return -2;
    }
    let mut board = [0u8; MAX_CELLS];
    const ROW_DELTA: [i32; 8] = [-1, -1, 0, 1, 1, 1, 0, -1];
    const COLUMN_DELTA: [i32; 8] = [0, 1, 1, 1, 0, -1, -1, -1];
    let mut state = seed_value as u64;
    position = 4;

    for _ in 0..word_count {
        let word_length = *values.add(position) as usize;
        position += 1;
        let word_start = position;
        position += word_length;
        let mut rows: [usize; MAX_DIMENSION] = std::array::from_fn(|index| index);
        let mut columns: [usize; MAX_DIMENSION] = std::array::from_fn(|index| index);
        shuffle(&mut rows[..height], &mut state);
        shuffle(&mut columns[..width], &mut state);
        let direction = (next_random(&mut state) % 8) as usize;
        let mut placed = false;

        for &row in &rows[..height] {
            for &column in &columns[..width] {
                let last_row = row as i32 + (word_length as i32 - 1) * ROW_DELTA[direction];
                let last_column = column as i32 + (word_length as i32 - 1) * COLUMN_DELTA[direction];
                if last_row < 0 || last_row >= height as i32 ||
                    last_column < 0 || last_column >= width as i32
                {
                    continue;
                }
                let positions: [usize; MAX_WORD_LENGTH] = std::array::from_fn(|offset| {
                    if offset < word_length {
                        let row = row as i32 + offset as i32 * ROW_DELTA[direction];
                        let column = column as i32 + offset as i32 * COLUMN_DELTA[direction];
                        row as usize * width + column as usize
                    } else {
                        0
                    }
                });
                if positions[..word_length].iter().any(|&cell| board[cell] != 0) {
                    continue;
                }
                for offset in 0..word_length {
                    board[positions[offset]] = *values.add(word_start + offset) as u8;
                }
                placed = true;
                break;
            }
            if placed {
                break;
            }
        }
    }
    for index in 0..cells {
        output.add(index).write(board[index]);
    }
    cells as i64
}
