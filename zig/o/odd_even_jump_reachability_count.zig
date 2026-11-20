const MAX_N: usize = 64;
const MAX_PARSEABLE: usize = 66;

fn comesBefore(input: [*]const i64, left: usize, right: usize, descending: bool) bool {
    const left_value = input[left + 1];
    const right_value = input[right + 1];
    if (left_value != right_value)
        return if (descending) left_value > right_value else left_value < right_value;
    return left < right;
}

fn buildSuccessors(input: [*]const i64, n: usize, descending: bool,
                   target: *[MAX_N]i64) void {
    var order: [MAX_N]usize = @splat(0);
    var stack: [MAX_N]usize = @splat(0);
    for (0..n) |i| {
        order[i] = i;
        target[i] = -1;
    }
    for (1..n) |i| {
        const key = order[i];
        var position = i;
        while (position > 0 and comesBefore(input, key, order[position - 1], descending)) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = key;
    }
    var stack_size: usize = 0;
    for (0..n) |i| {
        const index = order[i];
        while (stack_size > 0 and stack[stack_size - 1] < index) {
            stack_size -= 1;
            target[stack[stack_size]] = @intCast(index);
        }
        stack[stack_size] = index;
        stack_size += 1;
    }
}

export fn odd_even_jump_reachability_count(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > MAX_N) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| {
        const value = values[i + 1];
        if (value < -1_000_000 or value > 1_000_000) return -1;
    }
    var odd_next: [MAX_N]i64 = @splat(-1);
    var even_next: [MAX_N]i64 = @splat(-1);
    buildSuccessors(values, n, false, &odd_next);
    buildSuccessors(values, n, true, &even_next);
    var odd: [MAX_N]bool = @splat(false);
    var even: [MAX_N]bool = @splat(false);
    odd[n - 1] = true;
    even[n - 1] = true;
    var index = n - 1;
    while (index > 0) {
        index -= 1;
        if (odd_next[index] >= 0) odd[index] = even[@intCast(odd_next[index])];
        if (even_next[index] >= 0) even[index] = odd[@intCast(even_next[index])];
    }
    var count: i64 = 0;
    for (0..n) |i| if (odd[i]) { count += 1; };
    return count;
}
