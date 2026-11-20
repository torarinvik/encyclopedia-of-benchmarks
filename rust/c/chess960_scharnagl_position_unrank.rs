const MAX_POSITIONS: usize = 960;
const MAX_INPUT_WORDS: usize = 962;
const KNIGHT_FIRST: [usize; 10] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 3];
const KNIGHT_SECOND: [usize; 10] = [1, 2, 3, 4, 2, 3, 4, 3, 4, 4];

fn unrank_position(identifier: i64) -> [u8; 8] {
    let mut remainder = identifier as u64;
    let odd_bishop = (remainder % 4) as usize * 2 + 1;
    remainder /= 4;
    let even_bishop = (remainder % 4) as usize * 2;
    remainder /= 4;
    let queen_ordinal = (remainder % 6) as usize;
    let knight_ordinal = (remainder / 6) as usize;
    let mut board = [0u8; 8];
    board[odd_bishop] = b'B';
    board[even_bishop] = b'B';
    let mut open_files = [0usize; 8];
    let mut open_count = 0usize;
    for file in 0..8 {
        if board[file] == 0 { open_files[open_count] = file; open_count += 1; }
    }
    board[open_files[queen_ordinal]] = b'Q';
    open_count = 0;
    for file in 0..8 {
        if board[file] == 0 { open_files[open_count] = file; open_count += 1; }
    }
    board[open_files[KNIGHT_FIRST[knight_ordinal]]] = b'N';
    board[open_files[KNIGHT_SECOND[knight_ordinal]]] = b'N';
    for piece in [b'R', b'K', b'R'] {
        for file in 0..8 {
            if board[file] == 0 { board[file] = piece; break; }
        }
    }
    board
}

#[no_mangle]
pub unsafe extern "C" fn chess960_scharnagl_position_unrank(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_WORDS).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count_word = values[0];
    if !(0..=MAX_POSITIONS as i64).contains(&count_word) || length != count_word as usize + 1 { return -1; }
    let count = count_word as usize;
    if values[1..].iter().any(|&identifier| !(0..MAX_POSITIONS as i64).contains(&identifier)) { return -1; }
    let bytes = count * 8;
    if bytes != 0 && (output.is_null() || capacity < bytes) { return -2; }
    if bytes == 0 { return 0; }
    let destination = unsafe { std::slice::from_raw_parts_mut(output, bytes) };
    for item in 0..count {
        let board = unrank_position(values[item + 1]);
        destination[item * 8..item * 8 + 8].copy_from_slice(&board);
    }
    bytes as i64
}
