fn key(mask: usize, distances: *const [8]usize, n: usize) usize {
    var score: usize = 0;
    var bits: usize = 0;
    for (0..n) |i| if (mask & (@as(usize, 1) << @intCast(i)) != 0) { score += distances[i]*distances[i]; bits += 1; };
    return score*2304 + bits*256 + mask;
}
fn push(heap: *[256]usize, size: usize, mask: usize, distances: *const [8]usize, n: usize) usize {
    var at = size;
    const k = key(mask, distances, n);
    while (at > 0 and k < key(heap[(at-1)/2], distances, n)) { heap[at] = heap[(at-1)/2]; at = (at-1)/2; }
    heap[at] = mask;
    return size+1;
}
fn pop(heap: *[256]usize, size: usize, distances: *const [8]usize, n: usize) usize {
    const result = heap[0]; const remaining = size-1; const last = heap[remaining];
    var at: usize = 0;
    while (2*at+1 < remaining) {
        var child = 2*at+1;
        if (child+1 < remaining and key(heap[child+1], distances, n) < key(heap[child], distances, n)) child += 1;
        if (key(heap[child], distances, n) >= key(last, distances, n)) break;
        heap[at] = heap[child]; at = child;
    }
    if (remaining > 0) heap[at] = last;
    return result;
}
export fn multiprobe_lsh_probe_sequence(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > 7) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 4 or input[1] < 1 or input[1] > 1000) return -1;
    const m: usize = @intCast(input[0]); const width: usize = @intCast(input[1]);
    var limit: usize = 1;
    for (0..m) |_| limit *= 3;
    if (length != 3+m or input[2] < 0 or input[2] >= @as(i64, @intCast(limit))) return -1;
    const count: usize = @intCast(input[2]);
    var distances = [_]usize{0} ** 8; var coords = [_]usize{0} ** 8; var signs = [_]i32{0} ** 8;
    for (0..m) |i| {
        if (input[3+i] < 0 or input[3+i] > @as(i64, @intCast(width))) return -1;
        distances[2*i] = @intCast(input[3+i]); distances[2*i+1] = width-distances[2*i];
        coords[2*i] = i; coords[2*i+1] = i; signs[2*i] = -1; signs[2*i+1] = 1;
    }
    for (1..2*m) |i| {
        const d = distances[i]; const c = coords[i]; const s = signs[i]; var j = i;
        while (j > 0 and (distances[j-1] > d or (distances[j-1] == d and (coords[j-1] > c or (coords[j-1] == c and signs[j-1] > s))))) {
            distances[j] = distances[j-1]; coords[j] = coords[j-1]; signs[j] = signs[j-1]; j -= 1;
        }
        distances[j] = d; coords[j] = c; signs[j] = s;
    }
    var heap: [256]usize = undefined; var result: [80]u8 = undefined;
    var size = push(&heap, 0, 1, &distances, 2*m); var emitted: usize = 0;
    while (emitted < count) {
        const mask = pop(&heap, size, &distances, 2*m); size -= 1;
        var top: usize = 0;
        while ((@as(usize, 1) << @intCast(top+1)) <= mask) top += 1;
        if (top+1 < 2*m) {
            size = push(&heap, size, (mask ^ (@as(usize, 1) << @intCast(top))) | (@as(usize, 1) << @intCast(top+1)), &distances, 2*m);
            size = push(&heap, size, mask | (@as(usize, 1) << @intCast(top+1)), &distances, 2*m);
        }
        var seen: usize = 0; var valid = true;
        for (0..2*m) |i| if (mask & (@as(usize, 1) << @intCast(i)) != 0) {
            const bit = @as(usize, 1) << @intCast(coords[i]);
            if (seen & bit != 0) { valid = false; break; }
            seen |= bit;
        };
        if (valid) { result[emitted] = @intCast(mask); emitted += 1; }
    }
    if (output_opt == null or capacity < count) return -2;
    const output = output_opt.?;
    for (0..count) |i| output[i] = result[i];
    return @intCast(count);
}
