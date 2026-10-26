module prolangs_c_gnugo_liberty_count;

// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream countlib/count are under GNU GPL version 1; this derivative is licensed under GNU GPL version 1.
fn long prolangs_c_gnugo_liberty_count(long* input, usz length)
    @export("prolangs_c_gnugo_liberty_count") {
    if (input == null || length < 4 || length > 726) return -1;
    long row = input[0], col = input[1], color = input[2], count = input[3];
    if (row < 0 || row >= 19 || col < 0 || col >= 19 || (color != 1 && color != 2) || count < 0 || count > 361) return -1;
    if (length != 4 + 2 * count.usz()) return -1;
    u8[361] board = {0}; bool[361] seen = {false}; bool[361] liberties = {false};
    for (usz k = 0; k < count.usz(); k++) {
        long at = input[4 + 2*k], stone = input[5 + 2*k];
        if (at < 0 || at >= 361 || (stone != 1 && stone != 2) || board[at.usz()] != 0) return -1;
        board[at.usz()] = stone.u8();
    }
    usz start = (row * 19 + col).usz();
    if (board[start] != color.u8()) return -1;
    int[361] stack = {0}; usz top = 1; long total = 0;
    stack[0] = start.int(); seen[start] = true;
    while (top > 0) {
        top--;
        int at = stack[top], r = at / 19, c = at % 19;
        int[4] neighbors = {0}; usz n = 0;
        if (r > 0) { neighbors[n] = at - 19; n++; }
        if (r < 18) { neighbors[n] = at + 19; n++; }
        if (c > 0) { neighbors[n] = at - 1; n++; }
        if (c < 18) { neighbors[n] = at + 1; n++; }
        for (usz j = 0; j < n; j++) {
            usz next = neighbors[j].usz();
            if (board[next] == 0) {
                if (!liberties[next]) { liberties[next] = true; total++; }
            } else if (board[next] == color.u8() && !seen[next]) {
                seen[next] = true; stack[top] = next.int(); top++;
            }
        }
    }
    return total;
}
