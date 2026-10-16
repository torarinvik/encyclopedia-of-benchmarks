const MAX_LENGTH: usize = 512;
const FNV_OFFSET_BASIS: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

fn fnvWord(hash_input: u64, value: i64) u64 {
    var hash = hash_input;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        hash ^= (bits >> @intCast(8 * byte)) & 0xff;
        hash *%= FNV_PRIME;
    }
    return hash;
}

export fn kasai_algorithm(values_pointer: ?[*]const i64, length: usize) i64 {
    const values = values_pointer orelse return -1;
    if (length < 1 or values[0] < 0 or values[0] > MAX_LENGTH) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 2 * n) return -1;
    for (0..n) |i| {
        if (values[1 + i] < 0 or values[1 + i] > 127) return -1;
    }

    var suffixes: [MAX_LENGTH]usize = undefined;
    var rank: [MAX_LENGTH]usize = undefined;
    var seen = [_]bool{false} ** MAX_LENGTH;
    var lcp = [_]i64{0} ** MAX_LENGTH;
    for (0..n) |position| {
        const suffix_value = values[1 + n + position];
        if (suffix_value < 0 or @as(u64, @intCast(suffix_value)) >= n) return -1;
        const suffix: usize = @intCast(suffix_value);
        if (seen[suffix]) return -1;
        seen[suffix] = true;
        suffixes[position] = suffix;
        rank[suffix] = position;
    }

    if (n > 1) {
        for (1..n) |position| {
            const left = suffixes[position - 1];
            const right = suffixes[position];
            const left_tail_rank: i64 = if (left + 1 < n) @intCast(rank[left + 1]) else -1;
            const right_tail_rank: i64 = if (right + 1 < n) @intCast(rank[right + 1]) else -1;
            const left_byte = values[1 + left];
            const right_byte = values[1 + right];
            if (left_byte > right_byte or (left_byte == right_byte and left_tail_rank >= right_tail_rank)) return -1;
        }
    }

    var common: usize = 0;
    for (0..n) |start| {
        const current_rank = rank[start];
        if (current_rank == n - 1) {
            common = 0;
            continue;
        }
        const next_start = suffixes[current_rank + 1];
        while (start + common < n and next_start + common < n and
            values[1 + start + common] == values[1 + next_start + common]) : (common += 1) {}
        lcp[current_rank] = @intCast(common);
        if (common > 0) common -= 1;
    }

    var hash = fnvWord(FNV_OFFSET_BASIS, @intCast(n));
    for (0..n) |i| hash = fnvWord(hash, lcp[i]);
    return @intCast(hash & 0x7fffffffffffffff);
}
