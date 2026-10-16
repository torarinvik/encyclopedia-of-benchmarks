const LINES: [[usize; 3]; 8] = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6],
    [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6],
];

fn won(board: &[i64; 9], player: i64) -> bool {
    LINES.iter().any(|line| line.iter().all(|&i| board[i] == player))
}

fn search(board: &mut [i64; 9], side: i64) -> Option<(i64, i64)> {
    if won(board, 1) || won(board, 2) || !board.contains(&0) { return None; }
    let other = 3 - side;
    let mut best_rank = -1;
    let mut best_score = 0;
    let mut best_mask = 0;
    for index in 0..9 {
        if board[index] != 0 { continue; }
        board[index] = side;
        let score = if won(board, 1) { 1 }
            else if won(board, 2) { 2 }
            else { search(board, other).map_or(0, |result| result.0) };
        board[index] = 0;
        let rank = if score == side { 2 } else if score == 0 { 1 } else { 0 };
        if rank > best_rank { best_rank = rank; best_score = score; best_mask = 1 << index; }
        else if rank == best_rank { best_mask |= 1 << index; }
    }
    Some((best_score, best_mask))
}

#[no_mangle]
pub extern "C" fn depth_first_search_tic_tac_toe(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 10 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] != 1 && values[0] != 2 { return -1; }
    let mut board = [0i64; 9];
    for index in 0..9 {
        if !(0..=2).contains(&values[index + 1]) { return -1; }
        board[index] = values[index + 1];
    }
    search(&mut board, values[0]).map_or(0, |(score, mask)| 1 + score * 512 + mask)
}
