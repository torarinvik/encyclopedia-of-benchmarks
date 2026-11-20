/// Minimum digit sum of a 0/1 multiple using 0-1 BFS over residues.
fn minimumDigitSum(n: i64) i64 {
    var distance: [16]i64 = undefined;
    var deque: [512]usize = undefined;
    for (0..@as(usize, @intCast(n))) |i| distance[i] = 1000;
    var head: usize = 0;
    var tail: usize = 0;
    var queued: usize = 0;
    const start: usize = @intCast(@mod(1, n));
    distance[start] = 1;
    deque[tail] = start;
    tail = (tail + 1) % deque.len;
    queued += 1;
    while (queued > 0) {
        const residue = deque[head];
        head = (head + 1) % deque.len;
        queued -= 1;
        const zero_next: usize = @intCast(@mod(@as(i64, @intCast(residue)) * 10, n));
        if (distance[zero_next] > distance[residue]) {
            distance[zero_next] = distance[residue];
            head = (head + deque.len - 1) % deque.len;
            deque[head] = zero_next;
            queued += 1;
        }
        const one_next: usize = @intCast(@mod(@as(i64, @intCast(zero_next)) + 1, n));
        if (distance[one_next] > distance[residue] + 1) {
            distance[one_next] = distance[residue] + 1;
            deque[tail] = one_next;
            tail = (tail + 1) % deque.len;
            queued += 1;
        }
    }
    return distance[0];
}

export fn shortest_path_modulo_small_multiple(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const n = input_opt.?[0];
    if (n < 1 or n > 16) return -1;
    return minimumDigitSum(n);
}
