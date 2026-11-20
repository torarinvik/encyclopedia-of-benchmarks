const max_n: usize = 8;
const max_m: usize = 28;
const max_length: usize = 58;

export fn dag_transitive_reduction(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > max_length + 1) return -1;
    const words = input.?;
    if (words[0] < 1 or words[0] > @as(i64, @intCast(max_n)) or
        words[1] < 0 or words[1] > @as(i64, @intCast(max_m))) return -1;
    const n: usize = @intCast(words[0]);
    const m: usize = @intCast(words[1]);
    if (length != 2 + 2 * m) return -1;

    var outgoing = [_]usize{0} ** max_n;
    for (0..m) |edge| {
        const tail_value = words[2 + 2 * edge];
        const head_value = words[3 + 2 * edge];
        if (tail_value < 0 or head_value < 0 or
            @as(u64, @intCast(tail_value)) >= n or
            @as(u64, @intCast(head_value)) >= n or tail_value == head_value) return -1;
        const tail: usize = @intCast(tail_value);
        const head: usize = @intCast(head_value);
        const bit = @as(usize, 1) << @intCast(head);
        if ((outgoing[tail] & bit) != 0) return -1;
        outgoing[tail] |= bit;
    }

    var reach = outgoing;
    for (0..n) |middle| {
        const middle_bit = @as(usize, 1) << @intCast(middle);
        for (0..n) |source| {
            if ((reach[source] & middle_bit) != 0) reach[source] |= reach[middle];
        }
    }
    for (0..n) |vertex| {
        const self_bit = @as(usize, 1) << @intCast(vertex);
        if ((reach[vertex] & self_bit) != 0) return -1;
    }

    var retained: i64 = 0;
    for (0..m) |edge| {
        const tail: usize = @intCast(words[2 + 2 * edge]);
        const head: usize = @intCast(words[3 + 2 * edge]);
        var redundant = false;
        for (0..n) |middle| {
            const middle_bit = @as(usize, 1) << @intCast(middle);
            const head_bit = @as(usize, 1) << @intCast(head);
            if (middle != tail and middle != head and
                (outgoing[tail] & middle_bit) != 0 and (reach[middle] & head_bit) != 0) {
                redundant = true;
            }
        }
        if (!redundant) retained += 1;
    }
    return retained;
}
