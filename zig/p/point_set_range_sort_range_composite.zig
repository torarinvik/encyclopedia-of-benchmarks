const modulus: i64 = 998244353;
const max_length: usize = 210;
const Record = struct { priority: i64, a: i64, b: i64 };

export fn point_set_range_sort_range_composite(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > max_length) return -1;
    const values = input.?;
    const n_value = values[0];
    const q_value = values[1];
    if (n_value < 1 or n_value > 16 or q_value < 1 or q_value > 32) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length < 2 + 3 * n) return -1;
    var records: [16]Record = undefined;
    var seen: [48]i64 = undefined;
    var seen_count: usize = 0;
    var cursor: usize = 2;
    for (0..n) |i| {
        const p = values[cursor];
        const a = values[cursor + 1];
        const b = values[cursor + 2];
        cursor += 3;
        if (p < 0 or p > 1_000_000_000 or a < 1 or a >= modulus or b < 0 or b >= modulus) return -1;
        for (0..seen_count) |j| {
            if (seen[j] == p) return -1;
        }
        seen[seen_count] = p;
        seen_count += 1;
        records[i] = .{ .priority = p, .a = a, .b = b };
    }
    var checksum: i64 = 0;
    var query_number: i64 = 0;
    for (0..q) |_| {
        if (cursor >= length) return -1;
        const opcode = values[cursor];
        cursor += 1;
        if (opcode == 0) {
            if (length - cursor < 4) return -1;
            const index = values[cursor];
            const p = values[cursor + 1];
            const a = values[cursor + 2];
            const b = values[cursor + 3];
            cursor += 4;
            if (index < 0 or index >= n_value or p < 0 or p > 1_000_000_000 or a < 1 or a >= modulus or b < 0 or b >= modulus) return -1;
            for (0..seen_count) |j| {
                if (seen[j] == p) return -1;
            }
            seen[seen_count] = p;
            seen_count += 1;
            records[@intCast(index)] = .{ .priority = p, .a = a, .b = b };
        } else if (opcode == 1) {
            if (length - cursor < 3) return -1;
            const left = values[cursor];
            const right = values[cursor + 1];
            const x = values[cursor + 2];
            cursor += 3;
            if (left < 0 or left >= right or right > n_value or x < 0 or x >= modulus) return -1;
            var answer = x;
            for (@as(usize, @intCast(left))..@as(usize, @intCast(right))) |i| {
                answer = @mod(records[i].a * answer + records[i].b, modulus);
            }
            query_number += 1;
            checksum = @mod(checksum + query_number * answer, modulus);
        } else if (opcode == 2 or opcode == 3) {
            if (length - cursor < 2) return -1;
            const left = values[cursor];
            const right = values[cursor + 1];
            cursor += 2;
            if (left < 0 or left >= right or right > n_value) return -1;
            const start: usize = @intCast(left);
            const end: usize = @intCast(right);
            for (start + 1..end) |i| {
                const item = records[i];
                var j = i;
                while (j > start and (if (opcode == 2) records[j - 1].priority > item.priority else records[j - 1].priority < item.priority)) {
                    records[j] = records[j - 1];
                    j -= 1;
                }
                records[j] = item;
            }
        } else return -1;
    }
    if (cursor != length) return -1;
    return checksum;
}
