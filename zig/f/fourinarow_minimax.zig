const MAX_HISTORY: usize = 20;
const MAX_DEPTH: i64 = 7;
const HUGE: i32 = 100000;
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

fn has(board: u64, mask: u64) bool { return board & mask == mask; }
fn scoreBoard(human: u64, computer: u64) i32 {
    var total: i32 = 0;
    for (0..2) |player| {
        const b = if (player == 0) human else computer;
        const other = if (player == 0) computer else human;
        const sign: i32 = if (player == 0) -1 else 1;
        for (0..21) |i| { if (has(b, C4V << i)) total += sign * 1000; }
        for (0..6) |i| { for (0..4) |j| {
            if (has(b, C4H << (j + i * 6))) total += sign * 1000;
        } }
        for (0..3) |i| { for (0..4) |j| {
            if (has(b, C4UR << (j + i * 6))) total += sign * 1000;
            if (has(b, C4UL << (j + i * 6))) total += sign * 1000;
        } }
        for (0..21) |i| { if (has(b, C3V << i) and (other & (C4V << i)) == 0) total += sign * 20; }
        for (0..6) |i| { for (0..5) |j| {
            if (has(b, C3H << (j + i * 6))) total += sign * 20;
        } }
        for (0..3) |i| { for (0..4) |j| {
            if (has(b, C3UR << (j + i * 6))) total += sign * 20;
            if (has(b, C3UL << (j + i * 6))) total += sign * 20;
        } }
        for (0..21) |i| { if (has(b, C2V << i) and (other & (C4V << i)) == 0) total += sign * 5; }
        for (0..6) |i| { for (0..6) |j| {
            if (has(b, C2H << (j + i * 6))) total += sign * 5;
        } }
        for (0..3) |i| { for (0..4) |j| {
            if (has(b, C2UR << (j + i * 6))) total += sign * 5;
            if (has(b, C2UL << (j + i * 6))) total += sign * 5;
        } }
    }
    return total;
}
fn wins(board: u64) bool {
    for (0..6) |row| { for (0..7) |col| {
        for (0..2) |dc| { for (0..3) |dr_raw| {
            const dr: i32 = @as(i32, @intCast(dr_raw)) - 1;
            if (dc == 0 and dr <= 0) continue;
            const ec: i32 = @as(i32, @intCast(col)) + 3 * @as(i32, @intCast(dc));
            const er: i32 = @as(i32, @intCast(row)) + 3 * dr;
            if (ec >= 7 or er < 0 or er >= 6) continue;
            var line: u64 = 0;
            for (0..4) |step| {
                const s: i32 = @intCast(step);
                const cell = @as(i32, @intCast(col)) + s * @as(i32, @intCast(dc)) +
                    (@as(i32, @intCast(row)) + s * dr) * 7;
                line |= @as(u64, 1) << @intCast(cell);
            }
            if (board & line == line) return true;
        } }
    } }
    return false;
}
fn search(human: u64, computer: u64, side: i32, level: i32, limit: i32,
    mode: i32, alpha: i32, beta: i32) i32 {
    if (level >= limit) return scoreBoard(human, computer);
    if (side == 2) {
        var best: i32 = -HUGE;
        for (0..7) |col| {
            var row: usize = 0;
            while (row < 6 and ((human | computer) & (@as(u64, 1) << (col + row * 7))) != 0) : (row += 1) {}
            if (row == 6) continue;
            const value = search(human, computer | (@as(u64, 1) << (col + row * 7)), 1, level + 1, limit, mode, best, beta);
            if (value > best) best = value;
            if (mode == 2 and best > beta) return best;
        }
        return best;
    }
    var best: i32 = HUGE;
    for (0..7) |col| {
        var row: usize = 0;
        while (row < 6 and ((human | computer) & (@as(u64, 1) << (col + row * 7))) != 0) : (row += 1) {}
        if (row == 6) continue;
        const value = search(human | (@as(u64, 1) << (col + row * 7)), computer, 2, level + 1, limit, mode, alpha, best);
        if (value <= best) best = value;
        if (mode == 2 and best < alpha) return best;
    }
    return best;
}
fn evaluate(human: u64, computer: u64, side: i32, depth: i32, mode: i32) i64 {
    var best: i32 = if (side == 2) -HUGE else HUGE;
    var best_col: i32 = 0;
    for (0..7) |col| {
        var row: usize = 0;
        while (row < 6 and ((human | computer) & (@as(u64, 1) << (col + row * 7))) != 0) : (row += 1) {}
        if (row == 6) continue;
        const value = if (side == 2)
            search(human, computer | (@as(u64, 1) << (col + row * 7)), 1, 2, depth, mode, best, HUGE)
        else
            search(human | (@as(u64, 1) << (col + row * 7)), computer, 2, 2, depth, mode, -HUGE, best);
        if ((side == 2 and value > best) or (side == 1 and value <= best)) { best = value; best_col = @intCast(col); }
    }
    return @as(i64, best) * 8 + best_col;
}

pub export fn fourinarow_minimax(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > 4 + MAX_HISTORY) return -1;
    const depth = input[0]; const mode = input[1]; const side = input[2]; const count = input[3];
    if (depth < 2 or depth > MAX_DEPTH or (mode != 0 and mode != 2) or (side != 1 and side != 2) or
        count < 0 or count > MAX_HISTORY or length != 4 + @as(usize, @intCast(count)) or
        side != (if (@mod(count, 2) == 0) 1 else 2)) return -1;
    var human: u64 = 0; var computer: u64 = 0; var heights: [7]usize = .{0} ** 7;
    for (0..@as(usize, @intCast(count))) |turn| {
        const col_value = input[4 + turn];
        if (col_value < 0 or col_value >= 7) return -1;
        const col: usize = @intCast(col_value);
        if (heights[col] >= 6) return -1;
        const bit = @as(u64, 1) << (col + heights[col] * 7);
        if (turn % 2 == 0) human |= bit else computer |= bit;
        heights[col] += 1;
        if (wins(if (turn % 2 == 0) human else computer)) return -1;
    }
    return evaluate(human, computer, @intCast(side), @intCast(depth), @intCast(mode));
}
