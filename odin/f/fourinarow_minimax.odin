package fourinarow_minimax

import "core:c"

MAX_HISTORY :: 20
MAX_DEPTH :: 7
HUGE_SCORE :: 100000
C4V :: (u64(1) << 0) | (u64(1) << 7) | (u64(1) << 14) | (u64(1) << 21)
C3V :: C4V >> 7
C2V :: C3V >> 7
C4H :: u64(15)
C3H :: C4H >> 1
C2H :: C3H >> 1
C4UR :: (u64(1) << 0) | (u64(1) << 8) | (u64(1) << 16) | (u64(1) << 24)
C3UR :: C4UR >> 8
C2UR :: C3UR >> 8
C4UL :: (u64(1) << 3) | (u64(1) << 9) | (u64(1) << 15) | (u64(1) << 21)
C3UL :: C4UL >> 6
C2UL :: C3UL >> 6

has :: proc "contextless" (board, mask: u64) -> bool { return (board & mask) == mask }
score_board :: proc "contextless" (human, computer: u64) -> int {
    total := 0
    for player in 0..<2 {
        b := human; other := computer; sign := -1
        if player == 1 { b = computer; other = human; sign = 1 }
        for i in 0..<21 { if has(b, C4V << i) { total += sign * 1000 } }
        for i in 0..<6 { for j in 0..<4 { if has(b, C4H << (j+i*6)) { total += sign * 1000 } } }
        for i in 0..<3 { for j in 0..<4 {
            if has(b, C4UR << (j+i*6)) { total += sign * 1000 }
            if has(b, C4UL << (j+i*6)) { total += sign * 1000 }
        } }
        for i in 0..<21 { if has(b, C3V << i) && (other & (C4V << i)) == 0 { total += sign * 20 } }
        for i in 0..<6 { for j in 0..<5 { if has(b, C3H << (j+i*6)) { total += sign * 20 } } }
        for i in 0..<3 { for j in 0..<4 {
            if has(b, C3UR << (j+i*6)) { total += sign * 20 }
            if has(b, C3UL << (j+i*6)) { total += sign * 20 }
        } }
        for i in 0..<21 { if has(b, C2V << i) && (other & (C4V << i)) == 0 { total += sign * 5 } }
        for i in 0..<6 { for j in 0..<6 { if has(b, C2H << (j+i*6)) { total += sign * 5 } } }
        for i in 0..<3 { for j in 0..<4 {
            if has(b, C2UR << (j+i*6)) { total += sign * 5 }
            if has(b, C2UL << (j+i*6)) { total += sign * 5 }
        } }
    }
    return total
}
wins :: proc "contextless" (board: u64) -> bool {
    for row in 0..<6 { for col in 0..<7 {
        for dc in 0..2 { for dr in -1..2 {
            if dc == 0 && dr <= 0 { continue }
            ec := col+3*dc; er := row+3*dr
            if ec >= 7 || er < 0 || er >= 6 { continue }
            line: u64 = 0
            for k in 0..<4 { line |= u64(1) << (col+k*dc+(row+k*dr)*7) }
            if (board & line) == line { return true }
        } }
    } }
    return false
}
search :: proc "contextless" (human, computer: u64, side, level, limit, mode, alpha, beta: int) -> int {
    if level >= limit { return score_board(human, computer) }
    if side == 2 {
        best := -HUGE_SCORE
        for col in 0..<7 {
            row := 0
            for row < 6 && ((human | computer) & (u64(1) << (col+row*7))) != 0 { row += 1 }
            if row == 6 { continue }
            value := search(human, computer | (u64(1) << (col+row*7)), 1, level+1, limit, mode, best, beta)
            if value > best { best = value }
            if mode == 2 && best > beta { return best }
        }
        return best
    }
    best := HUGE_SCORE
    for col in 0..<7 {
        row := 0
        for row < 6 && ((human | computer) & (u64(1) << (col+row*7))) != 0 { row += 1 }
        if row == 6 { continue }
        value := search(human | (u64(1) << (col+row*7)), computer, 2, level+1, limit, mode, alpha, best)
        if value <= best { best = value }
        if mode == 2 && best < alpha { return best }
    }
    return best
}
evaluate :: proc "contextless" (human, computer: u64, side, depth, mode: int) -> i64 {
    best := HUGE_SCORE; if side == 2 { best = -HUGE_SCORE }
    best_col := 0
    for col in 0..<7 {
        row := 0
        for row < 6 && ((human | computer) & (u64(1) << (col+row*7))) != 0 { row += 1 }
        if row == 6 { continue }
        value := 0
        if side == 2 { value = search(human, computer | (u64(1) << (col+row*7)), 1, 2, depth, mode, best, HUGE_SCORE) }
        else { value = search(human | (u64(1) << (col+row*7)), computer, 2, 2, depth, mode, -HUGE_SCORE, best) }
        if (side == 2 && value > best) || (side == 1 && value <= best) { best = value; best_col = col }
    }
    return i64(best)*8+i64(best_col)
}

@(export)
fourinarow_minimax :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > c.size_t(4+MAX_HISTORY) do return -1
    depth, mode, side, count := input[0], input[1], input[2], input[3]
    if depth < 2 || depth > MAX_DEPTH || (mode != 0 && mode != 2) || (side != 1 && side != 2) || count < 0 || count > MAX_HISTORY || length != c.size_t(4+count) || side != (if count%2 == 0 then 1 else 2) do return -1
    human, computer: u64
    heights: [7]int
    for turn in 0..<int(count) {
        col_value := input[4+turn]
        if col_value < 0 || col_value >= 7 do return -1
        col := int(col_value)
        if heights[col] >= 6 do return -1
        bit := u64(1) << (col+heights[col]*7)
        if turn%2 == 0 { human |= bit } else { computer |= bit }
        heights[col] += 1
        if wins(if turn%2 == 0 then human else computer) do return -1
    }
    return evaluate(human, computer, int(side), int(depth), int(mode))
}
