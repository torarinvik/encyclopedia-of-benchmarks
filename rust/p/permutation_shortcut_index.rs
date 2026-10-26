const MAX_N: usize = 16;
const MAX_QUERIES: usize = 16;
const MAX_INPUT: usize = 52;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8;
    }
}

fn marked(bitmap: u32, vertex: usize) -> bool {
    bitmap & (1u32 << vertex) != 0
}

fn shortcut_inverse(target: usize, n: usize, successor: &[usize; MAX_N],
                    bitmap: u32, shortcuts: &[usize; MAX_N]) -> Option<usize> {
    let mut marker = target;
    let mut steps = 0;
    while steps < n && !marked(bitmap, marker) {
        marker = successor[marker];
        steps += 1;
    }
    if !marked(bitmap, marker) {
        let mut previous = target;
        let mut current = successor[target];
        while current != target {
            previous = current;
            current = successor[current];
        }
        return Some(previous);
    }
    let mut rank = 0;
    for vertex in 0..marker { if marked(bitmap, vertex) { rank += 1; } }
    let mut current = shortcuts[rank];
    let mut previous = current;
    current = successor[current];
    for _ in 0..n {
        if current == target { return Some(previous); }
        previous = current;
        current = successor[current];
    }
    None
}

#[no_mangle]
pub unsafe extern "C" fn permutation_shortcut_index(
    input_opt: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input_opt.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input_opt, length);
    let n_raw = input[0];
    let stride_raw = input[1];
    if n_raw < 1 || n_raw > MAX_N as i64 || stride_raw < 1 || stride_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    let stride = stride_raw as usize;
    let query_at = 2 + n;
    if length <= query_at { return -1; }
    let query_raw = input[query_at];
    if query_raw < 0 || query_raw > MAX_QUERIES as i64
        || length != query_at + 1 + 2 * query_raw as usize { return -1; }
    let query_count = query_raw as usize;
    let mut successor = [0usize; MAX_N];
    let mut seen = [false; MAX_N];
    for vertex in 0..n {
        let value = input[2 + vertex];
        if value < 1 || value > n_raw || seen[value as usize - 1] { return -1; }
        seen[value as usize - 1] = true;
        successor[vertex] = value as usize - 1;
    }
    for query in 0..query_count {
        let op = input[query_at + 1 + 2 * query];
        let index = input[query_at + 2 + 2 * query];
        if (op != 0 && op != 1) || index < 1 || index > n_raw { return -1; }
    }

    let mut visited = [false; MAX_N];
    let mut back_pointer = [usize::MAX; MAX_N];
    let mut bitmap = 0u32;
    for start in 0..n {
        if visited[start] { continue; }
        let mut cycle = [0usize; MAX_N];
        let mut cycle_length = 0usize;
        let mut current = start;
        while !visited[current] {
            visited[current] = true;
            cycle[cycle_length] = current;
            cycle_length += 1;
            current = successor[current];
        }
        if cycle_length >= stride {
            let mut offset = 0;
            while offset < cycle_length {
                let vertex = cycle[offset];
                bitmap |= 1u32 << vertex;
                let mut back_offset = (offset as isize - stride as isize) % cycle_length as isize;
                if back_offset < 0 { back_offset += cycle_length as isize; }
                back_pointer[vertex] = cycle[back_offset as usize];
                offset += stride;
            }
        }
    }
    let mut shortcuts = [usize::MAX; MAX_N];
    let mut shortcut_count = 0usize;
    for vertex in 0..n {
        if marked(bitmap, vertex) {
            shortcuts[shortcut_count] = back_pointer[vertex];
            shortcut_count += 1;
        }
    }

    let mut answers = [0i64; MAX_QUERIES];
    for query in 0..query_count {
        let op = input[query_at + 1 + 2 * query];
        let target = input[query_at + 2 + 2 * query] as usize - 1;
        let answer = if op == 0 { Some(successor[target]) }
            else { shortcut_inverse(target, n, &successor, bitmap, &shortcuts) };
        match answer {
            Some(value) => answers[query] = value as i64 + 1,
            None => return -1,
        }
    }
    let bytes = query_count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    for query in 0..query_count { store_i64_le(output, query * 8, answers[query]); }
    bytes as i64
}
