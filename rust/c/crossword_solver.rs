const MAX_CELLS: usize = 64;
const MAX_WORDS: usize = 8;
const MAX_WORD_LENGTH: usize = 8;

fn search(grid: &mut [i64; MAX_CELLS], rows: usize, cols: usize,
          words: &[[i64; MAX_WORD_LENGTH]; MAX_WORDS], lengths: &[usize; MAX_WORDS],
          remaining: &[usize]) -> bool {
    let mut start = 0;
    while start < rows * cols && grid[start] != 0 { start += 1; }
    if start == rows * cols { return true; }
    let row = start / cols;
    let col = start % cols;
    let mut current = remaining.to_vec();
    for (wi, &word_index) in remaining.iter().enumerate() {
        let word_length = lengths[word_index];
        for direction in 0..2 {
            let vertical = direction == 0;
            if (vertical && row + word_length > rows) || (!vertical && col + word_length > cols) { continue; }
            let positions: Vec<usize> = (0..word_length).map(|i| {
                if vertical { (row + i) * cols + col } else { row * cols + col + i }
            }).collect();
            if positions.iter().any(|&p| grid[p] != 0) { continue; }
            for (i, &p) in positions.iter().enumerate() { grid[p] = words[word_index][i]; }
            let mut next = current.clone();
            if let Some(index) = next.iter().position(|&candidate| candidate == word_index) { next.remove(index); }
            if let Some(index) = current.iter().position(|&candidate| candidate == word_index) { current.remove(index); }
            if search(grid, rows, cols, words, lengths, &next) { return true; }
            for p in positions { grid[p] = 0; }
            current.push(word_index);
        }
    }
    false
}

unsafe fn put_i64(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for i in 0..8 { *output.add(offset + i) = bytes[i]; }
}

#[no_mangle]
pub unsafe extern "C" fn crossword_solver(input: *const i64, length: usize,
                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (rv, cv, nv) = (values[0], values[1], values[2]);
    if !(1..=8).contains(&rv) || !(1..=8).contains(&cv) || !(0..=8).contains(&nv) { return -1; }
    let (rows, cols, count) = (rv as usize, cv as usize, nv as usize);
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
    for w in 0..count {
        if position >= length || !(1..=8).contains(&values[position]) { return -1; }
        lengths[w] = values[position] as usize;
        position += 1;
        if lengths[w] > length - position { return -1; }
        for i in 0..lengths[w] {
            if !(65..=90).contains(&values[position]) { return -1; }
            words[w][i] = values[position];
            position += 1;
        }
        for prior in 0..w {
            if lengths[prior] == lengths[w] && words[prior][..lengths[w]] == words[w][..lengths[w]] { return -1; }
        }
    }
    if position != length { return -1; }
    let remaining: Vec<usize> = (0..count).collect();
    let solved = search(&mut grid, rows, cols, &words, &lengths, &remaining);
    let required = (1 + rows * cols) * 8;
    if output.is_null() || capacity < required { return -2; }
    put_i64(output, 0, if solved { 1 } else { 0 });
    for i in 0..rows * cols { put_i64(output, (i + 1) * 8, grid[i]); }
    required as i64
}
