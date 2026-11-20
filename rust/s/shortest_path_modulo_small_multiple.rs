/// Minimum digit sum of a 0/1 multiple using 0-1 BFS on residue states.
fn minimum_digit_sum(n: i64) -> i64 {
    let mut distance = [i64::MAX; 16];
    let mut deque = [0usize; 512];
    let (mut head, mut tail, mut queued) = (0usize, 0usize, 0usize);
    let start = (1 % n) as usize;
    distance[start] = 1;
    deque[tail] = start;
    tail = (tail + 1) % deque.len();
    queued += 1;
    while queued > 0 {
        let residue = deque[head];
        head = (head + 1) % deque.len();
        queued -= 1;
        let zero_next = ((residue as i64 * 10) % n) as usize;
        if distance[zero_next] > distance[residue] {
            distance[zero_next] = distance[residue];
            head = (head + deque.len() - 1) % deque.len();
            deque[head] = zero_next;
            queued += 1;
        }
        let one_next = (zero_next as i64 + 1).rem_euclid(n) as usize;
        if distance[one_next] > distance[residue] + 1 {
            distance[one_next] = distance[residue] + 1;
            deque[tail] = one_next;
            tail = (tail + 1) % deque.len();
            queued += 1;
        }
    }
    distance[0]
}

#[no_mangle]
pub extern "C" fn shortest_path_modulo_small_multiple(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n = unsafe { *input };
    if !(1..=16).contains(&n) { return -1; }
    minimum_digit_sum(n)
}
