// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream countlib/count are under GNU GPL version 1; this derivative is licensed under GNU GPL version 1.
#[no_mangle]
pub unsafe extern "C" fn prolangs_c_gnugo_liberty_count(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=726).contains(&length) { return -1; }
    let row = *input; let col = *input.add(1); let color = *input.add(2); let count = *input.add(3);
    if !(0..19).contains(&row) || !(0..19).contains(&col) || !(color == 1 || color == 2) ||
        !(0..=361).contains(&count) || length != 4 + 2 * count as usize { return -1; }
    let mut board = [0u8; 361]; let mut seen = [false; 361]; let mut liberties = [false; 361];
    for k in 0..count as usize {
        let at = *input.add(4 + 2*k); let stone = *input.add(5 + 2*k);
        if !(0..361).contains(&at) || !(stone == 1 || stone == 2) || board[at as usize] != 0 { return -1; }
        board[at as usize] = stone as u8;
    }
    let start = (row * 19 + col) as usize;
    if board[start] != color as u8 { return -1; }
    let mut stack = [0usize; 361]; let mut top = 1usize; let mut total = 0i64;
    stack[0] = start; seen[start] = true;
    while top > 0 {
        top -= 1; let at = stack[top]; let r = at / 19; let c = at % 19;
        let mut neighbors = [0usize; 4]; let mut n = 0usize;
        if r > 0 { neighbors[n] = at - 19; n += 1; }
        if r < 18 { neighbors[n] = at + 19; n += 1; }
        if c > 0 { neighbors[n] = at - 1; n += 1; }
        if c < 18 { neighbors[n] = at + 1; n += 1; }
        for &next in &neighbors[..n] {
            if board[next] == 0 { if !liberties[next] { liberties[next] = true; total += 1; } }
            else if board[next] == color as u8 && !seen[next] { seen[next] = true; stack[top] = next; top += 1; }
        }
    }
    total
}
