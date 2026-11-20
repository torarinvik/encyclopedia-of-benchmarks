const MAX_Q: usize = 32;
const MAX_TAGS: usize = 64;
const MAX_INPUT: usize = 129;

export fn observed_remove_set(packed: ?[*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT) return -1;
    const input = packed orelse return -1;
    const qv = input[0];
    if (qv < 0 or qv > @as(i64, @intCast(MAX_Q)) or length != 1 + @as(usize, @intCast(qv)) * 4) return -1;
    const q: usize = @intCast(qv);
    for (0..q) |i| {
        const op = input[1 + 4 * i];
        const replica = input[2 + 4 * i];
        const element = input[3 + 4 * i];
        const peer = input[4 + 4 * i];
        if (op >= 0 and op <= 2) {
            if (replica < 0 or replica > 1 or element < 0 or element > 15 or peer != 0) return -1;
        } else if (op == 3 or op == 4) {
            if (replica < 0 or replica > 1 or element != 0 or peer < 0 or peer > 1) return -1;
        } else return -1;
    }

    var used = [_]bool{false} ** MAX_TAGS;
    var tag_element = [_]i64{0} ** MAX_TAGS;
    var next_sequence = [_]usize{0} ** 2;
    var additions = [_]bool{false} ** (2 * MAX_TAGS);
    var removals = [_]bool{false} ** (2 * MAX_TAGS);
    var answer: u64 = 0;
    var read_count: u6 = 0;
    for (0..q) |i| {
        const op = input[1 + 4 * i];
        const replica: usize = @intCast(input[2 + 4 * i]);
        const element = input[3 + 4 * i];
        const peer: usize = @intCast(input[4 + 4 * i]);
        const base = replica * MAX_TAGS;
        const peer_base = peer * MAX_TAGS;
        var result = false;
        if (op == 0) {
            const tag = replica * MAX_Q + next_sequence[replica];
            next_sequence[replica] += 1;
            used[tag] = true;
            tag_element[tag] = element;
            additions[base + tag] = true;
        } else if (op == 1) {
            for (0..MAX_TAGS) |tag| {
                if (additions[base + tag] and !removals[base + tag] and used[tag] and tag_element[tag] == element)
                    removals[base + tag] = true;
            }
        } else if (op == 2) {
            for (0..MAX_TAGS) |tag| {
                if (additions[base + tag] and !removals[base + tag] and used[tag] and tag_element[tag] == element)
                    result = true;
            }
        } else if (op == 3) {
            for (0..MAX_TAGS) |tag| {
                additions[base + tag] = additions[base + tag] or additions[peer_base + tag];
                removals[base + tag] = removals[base + tag] or removals[peer_base + tag];
            }
        } else {
            result = true;
            for (0..MAX_TAGS) |tag| {
                if ((additions[base + tag] and !additions[peer_base + tag]) or
                    (removals[base + tag] and !removals[peer_base + tag])) result = false;
            }
        }
        if (op == 2 or op == 4) {
            if (result) answer |= @as(u64, 1) << read_count;
            read_count += 1;
        }
    }
    return @intCast(answer);
}
