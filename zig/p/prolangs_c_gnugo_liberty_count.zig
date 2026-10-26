// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream countlib/count are under GNU GPL version 1; this derivative is licensed under GNU GPL version 1.
export fn prolangs_c_gnugo_liberty_count(input: [*]const i64, length: usize) i64 {
    if (length < 4 or length > 726) return -1;
    const row = input[0]; const col = input[1]; const color = input[2]; const count = input[3];
    if (row < 0 or row >= 19 or col < 0 or col >= 19 or (color != 1 and color != 2) or count < 0 or count > 361) return -1;
    if (length != 4 + 2 * @as(usize, @intCast(count))) return -1;
    var board = [_]u8{0} ** 361;
    var seen = [_]bool{false} ** 361;
    var liberties = [_]bool{false} ** 361;
    for (0..@as(usize, @intCast(count))) |k| {
        const raw_at = input[4 + 2*k]; const stone = input[5 + 2*k];
        if (raw_at < 0 or raw_at >= 361 or (stone != 1 and stone != 2)) return -1;
        const at: usize = @intCast(raw_at);
        if (board[at] != 0) return -1;
        board[at] = @intCast(stone);
    }
    const start: usize = @intCast(row * 19 + col);
    if (board[start] != color) return -1;
    var stack = [_]usize{0} ** 361;
    var top: usize = 1;
    var total: i64 = 0;
    stack[0] = start; seen[start] = true;
    while (top > 0) {
        top -= 1;
        const at = stack[top]; const r = at / 19; const c = at % 19;
        var neighbors = [_]usize{0} ** 4;
        var n: usize = 0;
        if (r > 0) { neighbors[n] = at - 19; n += 1; }
        if (r < 18) { neighbors[n] = at + 19; n += 1; }
        if (c > 0) { neighbors[n] = at - 1; n += 1; }
        if (c < 18) { neighbors[n] = at + 1; n += 1; }
        for (neighbors[0..n]) |next| {
            if (board[next] == 0) {
                if (!liberties[next]) { liberties[next] = true; total += 1; }
            } else if (board[next] == color and !seen[next]) {
                seen[next] = true; stack[top] = next; top += 1;
            }
        }
    }
    return total;
}
