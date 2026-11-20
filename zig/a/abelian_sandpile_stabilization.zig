const MAX_LENGTH: usize = 19;
const MAX_TOPPLES: usize = 1488;

export fn abelian_sandpile_stabilization(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_LENGTH) return -1;
    const rows_word = input[0];
    const cols_word = input[1];
    if (rows_word < 1 or rows_word > 4 or cols_word < 1 or cols_word > 4) return -1;
    const rows: usize = @intCast(rows_word);
    const cols: usize = @intCast(cols_word);
    const cells = rows * cols;
    if (length != 2 + cells) return -1;

    var board: [16]i64 = @splat(0);
    for (0..cells) |site| {
        const height = input[2 + site];
        if (height < 0 or height > 31) return -1;
        board[site] = height;
    }

    var queue: [16]usize = @splat(0);
    var queued: [16]bool = @splat(false);
    var head: usize = 0;
    var tail: usize = 0;
    var count: usize = 0;
    for (0..cells) |site| {
        if (board[site] >= 4) {
            queue[tail] = site;
            tail = (tail + 1) % cells;
            count += 1;
            queued[site] = true;
        }
    }

    var topples: usize = 0;
    while (count > 0) {
        const site = queue[head];
        head = (head + 1) % cells;
        count -= 1;
        queued[site] = false;
        if (board[site] < 4) continue;
        const row = site / cols;
        const col = site % cols;
        board[site] -= 4;
        topples += 1;
        if (topples > MAX_TOPPLES) return -1;

        if (row > 0) {
            const next = site - cols;
            board[next] += 1;
            if (board[next] >= 4 and !queued[next]) {
                queue[tail] = next; tail = (tail + 1) % cells; count += 1; queued[next] = true;
            }
        }
        if (col + 1 < cols) {
            const next = site + 1;
            board[next] += 1;
            if (board[next] >= 4 and !queued[next]) {
                queue[tail] = next; tail = (tail + 1) % cells; count += 1; queued[next] = true;
            }
        }
        if (row + 1 < rows) {
            const next = site + cols;
            board[next] += 1;
            if (board[next] >= 4 and !queued[next]) {
                queue[tail] = next; tail = (tail + 1) % cells; count += 1; queued[next] = true;
            }
        }
        if (col > 0) {
            const next = site - 1;
            board[next] += 1;
            if (board[next] >= 4 and !queued[next]) {
                queue[tail] = next; tail = (tail + 1) % cells; count += 1; queued[next] = true;
            }
        }
        if (board[site] >= 4 and !queued[site]) {
            queue[tail] = site; tail = (tail + 1) % cells; count += 1; queued[site] = true;
        }
    }

    var result: i64 = 0;
    var place: i64 = 1;
    for (0..cells) |site| {
        result += board[site] * place;
        place *= 4;
    }
    return result;
}
