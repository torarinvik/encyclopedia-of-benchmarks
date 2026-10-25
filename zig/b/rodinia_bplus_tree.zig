/// Root separator routes point lookup into one of two sorted B+ tree leaves.
export fn rodinia_bplus_tree(input: [*]const i64, length: usize) i64 {
    if (length < 7 or length > 31) return -1;
    if (input[0] < 1 or input[0] > 3 or input[1] < 1 or input[1] > 3 or input[2] < 1 or input[2] > 16) return -1;
    const left_n: usize = @intCast(input[0]);
    const right_n: usize = @intCast(input[1]);
    const query_n: usize = @intCast(input[2]);
    if (length != 3 + 2 * (left_n + right_n) + query_n) return -1;
    var keys: [2][3]i64 = .{ .{0, 0, 0}, .{0, 0, 0} };
    var vals: [2][3]i64 = .{ .{0, 0, 0}, .{0, 0, 0} };
    const counts = [2]usize{left_n, right_n};
    var cursor: usize = 3;
    for (0..2) |leaf| {
        for (0..counts[leaf]) |slot| {
            const key = input[cursor];
            const value = input[cursor + 1];
            cursor += 2;
            if (key < -1_000_000 or key > 1_000_000 or value < 0 or value > 1_000_000 or
                (slot > 0 and key <= keys[leaf][slot - 1])) return -1;
            keys[leaf][slot] = key;
            vals[leaf][slot] = value;
        }
    }
    if (keys[0][left_n - 1] >= keys[1][0]) return -1;
    var answer: i64 = 0;
    for (0..query_n) |qi| {
        const query = input[cursor];
        cursor += 1;
        if (query < -1_000_000 or query > 1_000_000) return -1;
        const leaf: usize = if (query < keys[1][0]) 0 else 1;
        for (0..counts[leaf]) |slot| {
            if (keys[leaf][slot] == query) {
                answer += @as(i64, @intCast(qi + 1)) * (vals[leaf][slot] + 1);
                break;
            }
        }
    }
    return answer;
}
