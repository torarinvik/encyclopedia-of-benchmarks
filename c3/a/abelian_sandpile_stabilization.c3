module abelian_sandpile_stabilization;

const usz MAX_LENGTH = 19;
const usz MAX_TOPPLES = 1488;

fn long abelian_sandpile_stabilization(long* input, usz length) @export("abelian_sandpile_stabilization") {
    if (input == null || length < 2 || length > MAX_LENGTH) return -1;
    long rows_word = input[0];
    long cols_word = input[1];
    if (rows_word < 1 || rows_word > 4 || cols_word < 1 || cols_word > 4) return -1;
    usz rows = (usz)rows_word;
    usz cols = (usz)cols_word;
    usz cells = rows * cols;
    if (length != 2 + cells) return -1;

    long[16] board = {};
    for (usz site = 0; site < cells; site += 1) {
        long height = input[2 + site];
        if (height < 0 || height > 31) return -1;
        board[site] = height;
    }

    usz[16] queue = {};
    bool[16] queued = {};
    usz head = 0, tail = 0, queue_count = 0;
    for (usz site = 0; site < cells; site += 1) {
        if (board[site] >= 4) {
            queue[tail] = site;
            tail = (tail + 1) % cells;
            queue_count += 1;
            queued[site] = true;
        }
    }

    usz topples = 0;
    while (queue_count > 0) {
        usz site = queue[head];
        head = (head + 1) % cells;
        queue_count -= 1;
        queued[site] = false;
        if (board[site] < 4) continue;
        usz row = site / cols;
        usz col = site % cols;
        board[site] -= 4;
        topples += 1;
        if (topples > MAX_TOPPLES) return -1;

        if (row > 0) {
            usz next = site - cols;
            board[next] += 1;
            if (board[next] >= 4 && !queued[next]) {
                queue[tail] = next; tail = (tail + 1) % cells; queue_count += 1; queued[next] = true;
            }
        }
        if (col + 1 < cols) {
            usz next = site + 1;
            board[next] += 1;
            if (board[next] >= 4 && !queued[next]) {
                queue[tail] = next; tail = (tail + 1) % cells; queue_count += 1; queued[next] = true;
            }
        }
        if (row + 1 < rows) {
            usz next = site + cols;
            board[next] += 1;
            if (board[next] >= 4 && !queued[next]) {
                queue[tail] = next; tail = (tail + 1) % cells; queue_count += 1; queued[next] = true;
            }
        }
        if (col > 0) {
            usz next = site - 1;
            board[next] += 1;
            if (board[next] >= 4 && !queued[next]) {
                queue[tail] = next; tail = (tail + 1) % cells; queue_count += 1; queued[next] = true;
            }
        }
        if (board[site] >= 4 && !queued[site]) {
            queue[tail] = site; tail = (tail + 1) % cells; queue_count += 1; queued[site] = true;
        }
    }

    long result = 0;
    long place = 1;
    for (usz site = 0; site < cells; site += 1) {
        result += board[site] * place;
        place *= 4;
    }
    return result;
}
