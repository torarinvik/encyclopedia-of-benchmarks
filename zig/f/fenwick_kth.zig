/// Fenwick frequency selection by binary lifting over prefix blocks.
export fn fenwick_kth(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 163) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 64 or input[1] < 0 or input[1] > 32) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    if (length != 2 + n + 3 * q) return -1;

    var frequency: [64]i64 = @splat(0);
    var tree: [65]i64 = @splat(0);
    var total: i64 = 0;
    for (0..n) |i| {
        const value = input[2 + i];
        if (value < 0 or value > 1_000_000) return -1;
        frequency[i] = value;
        total += value;
        const index = i + 1;
        tree[index] += value;
        const parent = index + (index & (~index + 1));
        if (parent <= n) tree[parent] += tree[index];
    }

    var result: i64 = 0;
    var query_number: usize = 0;
    var cursor: usize = 2 + n;
    for (0..q) |_| {
        const opcode = input[cursor];
        const first = input[cursor + 1];
        const second = input[cursor + 2];
        cursor += 3;
        if (opcode == 0) {
            if (first < 0 or first >= @as(i64, @intCast(n)) or second < -1_000_000 or second > 1_000_000) return -1;
            const position: usize = @intCast(first);
            const updated = frequency[position] + second;
            if (updated < 0 or updated > 1_000_000) return -1;
            frequency[position] = updated;
            total += second;
            var index = position + 1;
            while (index <= n) {
                tree[index] += second;
                index += index & (~index + 1);
            }
        } else if (opcode == 1) {
            if (second != 0) return -1;
            var answer: i64 = -1;
            if (first > 0 and first <= total) {
                var index: usize = 0;
                var step: usize = 1;
                while (step <= n / 2) : (step *= 2) {}
                var rank = first;
                while (step != 0) : (step /= 2) {
                    const candidate = index + step;
                    if (candidate <= n and tree[candidate] < rank) {
                        index = candidate;
                        rank -= tree[candidate];
                    }
                }
                answer = @intCast(index);
            }
            result += @as(i64, @intCast(query_number + 1)) * (answer + 1);
            query_number += 1;
        } else {
            return -1;
        }
    }
    return result;
}
