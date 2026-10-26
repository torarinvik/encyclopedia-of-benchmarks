const MAX_N: usize = 16;
const MAX_M: usize = 120;
const MAX_INPUT: usize = 243;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn lex_bfs(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    let start64 = *input.add(2);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || start64 < 0 || start64 >= n64 || length != 3 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let start = start64 as usize;
    let mut adjacency = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let u64 = *input.add(3 + 2 * edge);
        let v64 = *input.add(4 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacency[u][v] { return -1; }
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut labels = [[0i64; MAX_N]; MAX_N];
    let mut label_len = [0usize; MAX_N];
    let mut order = [0i64; MAX_N];
    let mut selected = [false; MAX_N];
    let mut current = start;
    for step in 0..n {
        if step > 0 {
            let mut have_best = false;
            for vertex in 0..n {
                if selected[vertex] { continue; }
                if !have_best { current = vertex; have_best = true; continue; }
                let shared = label_len[vertex].min(label_len[current]);
                let mut position = 0;
                let mut decided = false;
                while position < shared {
                    if labels[vertex][position] != labels[current][position] {
                        if labels[vertex][position] > labels[current][position] { current = vertex; }
                        decided = true;
                        break;
                    }
                    position += 1;
                }
                if !decided && (label_len[vertex] > label_len[current] ||
                    (label_len[vertex] == label_len[current] && vertex < current)) {
                    current = vertex;
                }
            }
        }
        selected[current] = true;
        order[step] = current as i64;
        for neighbor in 0..n {
            if !adjacency[current][neighbor] || selected[neighbor] { continue; }
            for position in (1..=label_len[neighbor]).rev() {
                labels[neighbor][position] = labels[neighbor][position - 1];
            }
            labels[neighbor][0] = step as i64;
            label_len[neighbor] += 1;
        }
    }
    for index in 0..n { store_i64_le(output, 8 * index, order[index]); }
    output_bytes as i64
}
