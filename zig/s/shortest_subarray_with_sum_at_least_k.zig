const max_count: usize = 256;
const max_input: usize = 259;

export fn shortest_subarray_with_sum_at_least_k(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const target = input[0];
    const count64 = input[1];
    if (target < -4096 or target > 4096 or count64 < 0 or count64 > 256) return -1;
    const count: usize = @intCast(count64);
    if (length != count + 2) return -1;

    var prefix: [max_count + 1]i64 = [_]i64{0} ** (max_count + 1);
    for (0..count) |index| {
        const value = input[index + 2];
        if (value < -1000 or value > 1000) return -1;
        prefix[index + 1] = prefix[index] + value;
    }

    var deque: [max_count + 1]usize = [_]usize{0} ** (max_count + 1);
    var head: usize = 0;
    var tail: usize = 0;
    var best: usize = count + 1;
    for (0..count + 1) |right| {
        while (head < tail and prefix[right] - prefix[deque[head]] >= target) {
            best = @min(best, right - deque[head]);
            head += 1;
        }
        while (head < tail and prefix[right] <= prefix[deque[tail - 1]]) tail -= 1;
        deque[tail] = right;
        tail += 1;
    }
    return if (best <= count) @intCast(best) else 0;
}

