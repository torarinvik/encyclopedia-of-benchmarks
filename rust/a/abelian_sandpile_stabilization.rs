const MAX_LENGTH: usize = 19;
const MAX_TOPPLES: usize = 1488;

#[no_mangle]
pub unsafe extern "C" fn abelian_sandpile_stabilization(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_LENGTH).contains(&length) { return -1; }
    let rows_word = *input;
    let cols_word = *input.add(1);
    if !(1..=4).contains(&rows_word) || !(1..=4).contains(&cols_word) { return -1; }
    let rows = rows_word as usize;
    let cols = cols_word as usize;
    let cells = rows * cols;
    if length != 2 + cells { return -1; }

    let mut board = [0i64; 16];
    for site in 0..cells {
        let height = *input.add(2 + site);
        if !(0..=31).contains(&height) { return -1; }
        board[site] = height;
    }

    let mut queue = [0usize; 16];
    let mut queued = [false; 16];
    let (mut head, mut tail, mut count) = (0usize, 0usize, 0usize);
    for site in 0..cells {
        if board[site] >= 4 {
            queue[tail] = site;
            tail = (tail + 1) % cells;
            count += 1;
            queued[site] = true;
        }
    }

    let mut topples = 0usize;
    while count > 0 {
        let site = queue[head];
        head = (head + 1) % cells;
        count -= 1;
        queued[site] = false;
        if board[site] < 4 { continue; }
        let row = site / cols;
        let col = site % cols;
        board[site] -= 4;
        topples += 1;
        if topples > MAX_TOPPLES { return -1; }

        if row > 0 {
            let next = site - cols;
            board[next] += 1;
            if board[next] >= 4 && !queued[next] {
                queue[tail] = next; tail = (tail + 1) % cells; count += 1; queued[next] = true;
            }
        }
        if col + 1 < cols {
            let next = site + 1;
            board[next] += 1;
            if board[next] >= 4 && !queued[next] {
                queue[tail] = next; tail = (tail + 1) % cells; count += 1; queued[next] = true;
            }
        }
        if row + 1 < rows {
            let next = site + cols;
            board[next] += 1;
            if board[next] >= 4 && !queued[next] {
                queue[tail] = next; tail = (tail + 1) % cells; count += 1; queued[next] = true;
            }
        }
        if col > 0 {
            let next = site - 1;
            board[next] += 1;
            if board[next] >= 4 && !queued[next] {
                queue[tail] = next; tail = (tail + 1) % cells; count += 1; queued[next] = true;
            }
        }
        if board[site] >= 4 && !queued[site] {
            queue[tail] = site; tail = (tail + 1) % cells; count += 1; queued[site] = true;
        }
    }

    let mut result = 0i64;
    let mut place = 1i64;
    for height in &board[..cells] {
        result += *height * place;
        place *= 4;
    }
    result
}
