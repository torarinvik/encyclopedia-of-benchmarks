module main

const max_history = 20
const max_depth = 7
const huge_score = 100000
const c4v = u64(1) | (u64(1) << 7) | (u64(1) << 14) | (u64(1) << 21)
const c3v = c4v >> 7
const c2v = c3v >> 7
const c4h = u64(15)
const c3h = c4h >> 1
const c2h = c3h >> 1
const c4ur = u64(1) | (u64(1) << 8) | (u64(1) << 16) | (u64(1) << 24)
const c3ur = c4ur >> 8
const c2ur = c3ur >> 8
const c4ul = (u64(1) << 3) | (u64(1) << 9) | (u64(1) << 15) | (u64(1) << 21)
const c3ul = c4ul >> 6
const c2ul = c3ul >> 6

fn has(board u64, mask u64) bool { return (board & mask) == mask }
fn score_board(human u64, computer u64) int {
    mut total := 0
    for player in 0 .. 2 {
        b := if player == 0 { human } else { computer }
        other := if player == 0 { computer } else { human }
        sign := if player == 0 { -1 } else { 1 }
        for i in 0 .. 21 { if has(b, c4v << i) { total += sign * 1000 } }
        for i in 0 .. 6 { for j in 0 .. 4 { if has(b, c4h << (j + i * 6)) { total += sign * 1000 } } }
        for i in 0 .. 3 { for j in 0 .. 4 {
            if has(b, c4ur << (j + i * 6)) { total += sign * 1000 }
            if has(b, c4ul << (j + i * 6)) { total += sign * 1000 }
        } }
        for i in 0 .. 21 { if has(b, c3v << i) && (other & (c4v << i)) == 0 { total += sign * 20 } }
        for i in 0 .. 6 { for j in 0 .. 5 { if has(b, c3h << (j + i * 6)) { total += sign * 20 } } }
        for i in 0 .. 3 { for j in 0 .. 4 {
            if has(b, c3ur << (j + i * 6)) { total += sign * 20 }
            if has(b, c3ul << (j + i * 6)) { total += sign * 20 }
        } }
        for i in 0 .. 21 { if has(b, c2v << i) && (other & (c4v << i)) == 0 { total += sign * 5 } }
        for i in 0 .. 6 { for j in 0 .. 6 { if has(b, c2h << (j + i * 6)) { total += sign * 5 } } }
        for i in 0 .. 3 { for j in 0 .. 4 {
            if has(b, c2ur << (j + i * 6)) { total += sign * 5 }
            if has(b, c2ul << (j + i * 6)) { total += sign * 5 }
        } }
    }
    return total
}
fn wins(board u64) bool {
    for row in 0 .. 6 { for col in 0 .. 7 {
        for dc in 0 .. 2 { for dr in -1 .. 2 {
            if dc == 0 && dr <= 0 { continue }
            ec := col + 3 * dc; er := row + 3 * dr
            if ec >= 7 || er < 0 || er >= 6 { continue }
            mut line := u64(0)
            for k in 0 .. 4 { line |= u64(1) << (col + k * dc + (row + k * dr) * 7) }
            if (board & line) == line { return true }
        } }
    } }
    return false
}
fn search(human u64, computer u64, side int, level int, limit int, mode int, alpha int, beta int) int {
    if level >= limit { return score_board(human, computer) }
    if side == 2 {
        mut best := -huge_score
        for col in 0 .. 7 {
            mut row := 0
            for row < 6 && ((human | computer) & (u64(1) << (col + row * 7))) != 0 { row++ }
            if row == 6 { continue }
            value := search(human, computer | (u64(1) << (col + row * 7)), 1, level + 1, limit, mode, best, beta)
            if value > best { best = value }
            if mode == 2 && best > beta { return best }
        }
        return best
    }
    mut best := huge_score
    for col in 0 .. 7 {
        mut row := 0
        for row < 6 && ((human | computer) & (u64(1) << (col + row * 7))) != 0 { row++ }
        if row == 6 { continue }
        value := search(human | (u64(1) << (col + row * 7)), computer, 2, level + 1, limit, mode, alpha, best)
        if value <= best { best = value }
        if mode == 2 && best < alpha { return best }
    }
    return best
}
fn evaluate(human u64, computer u64, side int, depth int, mode int) i64 {
    mut best := if side == 2 { -huge_score } else { huge_score }
    mut best_col := 0
    for col in 0 .. 7 {
        mut row := 0
        for row < 6 && ((human | computer) & (u64(1) << (col + row * 7))) != 0 { row++ }
        if row == 6 { continue }
        value := if side == 2 {
            search(human, computer | (u64(1) << (col + row * 7)), 1, 2, depth, mode, best, huge_score)
        } else {
            search(human | (u64(1) << (col + row * 7)), computer, 2, 2, depth, mode, -huge_score, best)
        }
        if (side == 2 && value > best) || (side == 1 && value <= best) { best = value; best_col = col }
    }
    return i64(best) * 8 + i64(best_col)
}

@[export: 'fourinarow_minimax']
pub fn fourinarow_minimax(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 4 || length > 4 + max_history { return -1 }
    depth := unsafe { input[0] }; mode := unsafe { input[1] }; side := unsafe { input[2] }; count := unsafe { input[3] }
    expected_side := if count % 2 == 0 { i64(1) } else { i64(2) }
    if depth < 2 || depth > max_depth || (mode != 0 && mode != 2) || (side != 1 && side != 2) || count < 0 || count > max_history || length != usize(4 + count) || side != expected_side { return -1 }
    mut human := u64(0); mut computer := u64(0); mut heights := [7]int{}
    for turn in 0 .. int(count) {
        col_value := unsafe { input[4 + turn] }
        if col_value < 0 || col_value >= 7 { return -1 }
        col := int(col_value); if heights[col] >= 6 { return -1 }
        bit := u64(1) << (col + heights[col] * 7)
        if turn % 2 == 0 { human |= bit } else { computer |= bit }
        heights[col]++
        if wins(if turn % 2 == 0 { human } else { computer }) { return -1 }
    }
    return evaluate(human, computer, int(side), int(depth), int(mode))
}
