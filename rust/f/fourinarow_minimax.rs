const MAX_HISTORY: usize = 20;
const MAX_DEPTH: i64 = 7;
const HUGE: i32 = 100_000;
const C4V: u64 = (1 << 0) | (1 << 7) | (1 << 14) | (1 << 21);
const C3V: u64 = C4V >> 7;
const C2V: u64 = C3V >> 7;
const C4H: u64 = 15;
const C3H: u64 = C4H >> 1;
const C2H: u64 = C3H >> 1;
const C4UR: u64 = (1 << 0) | (1 << 8) | (1 << 16) | (1 << 24);
const C3UR: u64 = C4UR >> 8;
const C2UR: u64 = C3UR >> 8;
const C4UL: u64 = (1 << 3) | (1 << 9) | (1 << 15) | (1 << 21);
const C3UL: u64 = C4UL >> 6;
const C2UL: u64 = C3UL >> 6;

fn has(board: u64, mask: u64) -> bool { board & mask == mask }

fn score_board(human: u64, computer: u64) -> i32 {
    let mut total = 0;
    for player in 0..2 {
        let b = if player == 0 { human } else { computer };
        let other = if player == 0 { computer } else { human };
        let sign = if player == 0 { -1 } else { 1 };
        for i in 0..21 { if has(b, C4V << i) { total += sign * 1000; } }
        for i in 0..6 { for j in 0..4 { if has(b, C4H << (j + i * 6)) { total += sign * 1000; } } }
        for i in 0..3 { for j in 0..4 {
            if has(b, C4UR << (j + i * 6)) { total += sign * 1000; }
            if has(b, C4UL << (j + i * 6)) { total += sign * 1000; }
        } }
        for i in 0..21 { if has(b, C3V << i) && other & (C4V << i) == 0 { total += sign * 20; } }
        for i in 0..6 { for j in 0..5 { if has(b, C3H << (j + i * 6)) { total += sign * 20; } } }
        for i in 0..3 { for j in 0..4 {
            if has(b, C3UR << (j + i * 6)) { total += sign * 20; }
            if has(b, C3UL << (j + i * 6)) { total += sign * 20; }
        } }
        for i in 0..21 { if has(b, C2V << i) && other & (C4V << i) == 0 { total += sign * 5; } }
        for i in 0..6 { for j in 0..6 { if has(b, C2H << (j + i * 6)) { total += sign * 5; } } }
        for i in 0..3 { for j in 0..4 {
            if has(b, C2UR << (j + i * 6)) { total += sign * 5; }
            if has(b, C2UL << (j + i * 6)) { total += sign * 5; }
        } }
    }
    total
}

fn wins(board: u64) -> bool {
    for row in 0..6i32 { for col in 0..7i32 {
        for dc in 0..=1i32 { for dr in -1..=1i32 {
            if dc == 0 && dr <= 0 { continue; }
            let ec = col + 3 * dc; let er = row + 3 * dr;
            if ec >= 7 || er < 0 || er >= 6 { continue; }
            let mut line = 0u64;
            for k in 0..4i32 { line |= 1u64 << (col + k * dc + (row + k * dr) * 7); }
            if board & line == line { return true; }
        } }
    } }
    false
}

fn search(human: u64, computer: u64, side: i32, level: i32, limit: i32,
           mode: i32, alpha: i32, beta: i32) -> i32 {
    if level >= limit { return score_board(human, computer); }
    if side == 2 {
        let mut best = -HUGE;
        for col in 0..7i32 {
            let mut row = 0;
            while row < 6 && ((human | computer) & (1u64 << (col + row * 7))) != 0 { row += 1; }
            if row == 6 { continue; }
            let value = search(human, computer | (1u64 << (col + row * 7)), 1, level + 1, limit, mode, best, beta);
            if value > best { best = value; }
            if mode == 2 && best > beta { return best; }
        }
        best
    } else {
        let mut best = HUGE;
        for col in 0..7i32 {
            let mut row = 0;
            while row < 6 && ((human | computer) & (1u64 << (col + row * 7))) != 0 { row += 1; }
            if row == 6 { continue; }
            let value = search(human | (1u64 << (col + row * 7)), computer, 2, level + 1, limit, mode, alpha, best);
            if value <= best { best = value; }
            if mode == 2 && best < alpha { return best; }
        }
        best
    }
}

fn evaluate(human: u64, computer: u64, side: i32, depth: i32, mode: i32) -> i64 {
    let mut best = if side == 2 { -HUGE } else { HUGE };
    let mut best_col = 0;
    for col in 0..7i32 {
        let mut row = 0;
        while row < 6 && ((human | computer) & (1u64 << (col + row * 7))) != 0 { row += 1; }
        if row == 6 { continue; }
        let value = if side == 2 {
            search(human, computer | (1u64 << (col + row * 7)), 1, 2, depth, mode, best, HUGE)
        } else {
            search(human | (1u64 << (col + row * 7)), computer, 2, 2, depth, mode, -HUGE, best)
        };
        if (side == 2 && value > best) || (side == 1 && value <= best) { best = value; best_col = col; }
    }
    i64::from(best) * 8 + i64::from(best_col)
}

#[no_mangle]
pub unsafe extern "C" fn fourinarow_minimax(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 4 + MAX_HISTORY { return -1; }
    let depth = *input;
    let mode = *input.add(1);
    let side = *input.add(2);
    let count = *input.add(3);
    if depth < 2 || depth > MAX_DEPTH || (mode != 0 && mode != 2) || (side != 1 && side != 2)
        || count < 0 || count > MAX_HISTORY as i64 || length != 4 + count as usize
        || side != if count % 2 == 0 { 1 } else { 2 } { return -1; }
    let mut human = 0u64;
    let mut computer = 0u64;
    let mut heights = [0i32; 7];
    for turn in 0..count as usize {
        let col_value = *input.add(4 + turn);
        if !(0..7).contains(&col_value) { return -1; }
        let col = col_value as usize;
        if heights[col] >= 6 { return -1; }
        let bit = 1u64 << (col as i32 + heights[col] * 7);
        if turn % 2 == 0 { human |= bit; } else { computer |= bit; }
        heights[col] += 1;
        if wins(if turn % 2 == 0 { human } else { computer }) { return -1; }
    }
    evaluate(human, computer, side as i32, depth as i32, mode as i32)
}
