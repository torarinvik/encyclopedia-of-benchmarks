const MAX_CELLS: usize = 64;
const MAX_WORDS: usize = 8;
const MAX_WORD_LENGTH: usize = 8;

fn search(grid: &mut [i64; MAX_CELLS], rows: usize, cols: usize,
          words: &[[i64; MAX_WORD_LENGTH]; MAX_WORDS], lengths: &[usize; MAX_WORDS],
          order: &[usize; MAX_WORDS], depth: usize, word_count: usize) -> bool {
    if depth == word_count { return true; }
    let word_index = order[depth];
    let word_length = lengths[word_index];
    for row in 0..rows {
        for col in 0..cols {
            for direction in 0..2 {
                let vertical = direction == 0;
                if (vertical && row + word_length > rows) || (!vertical && col + word_length > cols) { continue; }
                let mut cells = [0usize; MAX_WORD_LENGTH];
                let mut newly_filled = [false; MAX_WORD_LENGTH];
                let mut valid = true;
                for i in 0..word_length {
                    let cell = if vertical { (row + i) * cols + col } else { row * cols + col + i };
                    cells[i] = cell;
                    if grid[cell] != 0 && grid[cell] != words[word_index][i] { valid = false; }
                }
                if !valid { continue; }
                for i in 0..word_length {
                    newly_filled[i] = grid[cells[i]] == 0;
                    grid[cells[i]] = words[word_index][i];
                }
                if search(grid, rows, cols, words, lengths, order, depth + 1, word_count) { return true; }
                for i in 0..word_length { if newly_filled[i] { grid[cells[i]] = 0; } }
            }
        }
    }
    false
}

unsafe fn put_i64(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for i in 0..8 { *output.add(offset + i) = bytes[i]; }
}

#[no_mangle]
pub unsafe extern "C" fn crossword_puzzle_solver(input: *const i64, length: usize,
                                                    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (rv, cv, nv) = (values[0], values[1], values[2]);
    if !(1..=8).contains(&rv) || !(1..=8).contains(&cv) || !(0..=8).contains(&nv) { return -1; }
    let (rows, cols, word_count) = (rv as usize, cv as usize, nv as usize);
    if length < 3 + rows * cols { return -1; }
    let mut grid = [0i64; MAX_CELLS];
    for i in 0..rows * cols {
        let value = values[3 + i];
        if value != 0 && value != -1 && !(65..=90).contains(&value) { return -1; }
        grid[i] = value;
    }
    let mut words = [[0i64; MAX_WORD_LENGTH]; MAX_WORDS];
    let mut lengths = [0usize; MAX_WORDS];
    let mut position = 3 + rows * cols;
    for w in 0..word_count {
        if position >= length || !(1..=MAX_WORD_LENGTH as i64).contains(&values[position]) { return -1; }
        lengths[w] = values[position] as usize;
        position += 1;
        if lengths[w] > length - position { return -1; }
        for i in 0..lengths[w] {
            let letter = values[position];
            if !(65..=90).contains(&letter) { return -1; }
            words[w][i] = letter;
            position += 1;
        }
    }
    if position != length { return -1; }
    let mut order = [0usize; MAX_WORDS];
    for i in 0..word_count { order[i] = i; }
    for i in 1..word_count {
        let value = order[i];
        let mut j = i;
        while j > 0 && lengths[order[j - 1]] < lengths[value] { order[j] = order[j - 1]; j -= 1; }
        order[j] = value;
    }
    let solved = search(&mut grid, rows, cols, &words, &lengths, &order, 0, word_count);
    let required = (1 + rows * cols) * 8;
    if output.is_null() || capacity < required { return -2; }
    put_i64(output, 0, if solved { 1 } else { 0 });
    for i in 0..rows * cols { put_i64(output, (i + 1) * 8, grid[i]); }
    required as i64
}
