const MAX_ITEMS: usize = 16;
const MAX_CAPACITY: usize = 32;
const MAX_INPUT_LENGTH: usize = 19;

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const raw_count = input[0];
    const raw_capacity = input[1];
    if (raw_count < 1 or raw_count > MAX_ITEMS or raw_capacity < 1 or raw_capacity > MAX_CAPACITY)
        return null;
    const count: usize = @intCast(raw_count);
    const capacity: usize = @intCast(raw_capacity);
    if (input.len != count + 2) return null;

    var remaining_size: [MAX_ITEMS]i64 = @splat(0);
    var remaining_item: [MAX_ITEMS]usize = @splat(0);
    var assigned_bin: [MAX_ITEMS]i64 = @splat(0);
    for (0..count) |index| {
        const size = input[index + 2];
        if (size < 1 or size > raw_capacity) return null;
        remaining_size[index] = size;
        remaining_item[index] = index;
    }

    var remaining_count = count;
    var bin_count: i64 = 0;
    while (remaining_count > 0) {
        var reachable: [MAX_ITEMS + 1][MAX_CAPACITY + 1]bool = @splat(@splat(false));
        reachable[remaining_count][0] = true;
        var row = remaining_count;
        while (row > 0) {
            row -= 1;
            const size: usize = @intCast(remaining_size[row]);
            for (0..capacity + 1) |sum| {
                reachable[row][sum] = reachable[row + 1][sum];
                if (sum >= size and reachable[row + 1][sum - size])
                    reachable[row][sum] = true;
            }
        }

        var target = capacity;
        while (target > 0 and !reachable[0][target]) target -= 1;
        var selected: [MAX_ITEMS]bool = @splat(false);
        var needed = target;
        for (0..remaining_count) |item| {
            const size: usize = @intCast(remaining_size[item]);
            if (size <= needed and reachable[item + 1][needed - size]) {
                selected[item] = true;
                needed -= size;
                assigned_bin[remaining_item[item]] = bin_count;
            }
        }

        var survivors: usize = 0;
        for (0..remaining_count) |item| {
            if (!selected[item]) {
                remaining_size[survivors] = remaining_size[item];
                remaining_item[survivors] = remaining_item[item];
                survivors += 1;
            }
        }
        remaining_count = survivors;
        bin_count += 1;
    }

    var checksum = bin_count * 10000;
    for (0..count) |index|
        checksum += (@as(i64, @intCast(index)) + 1) * (assigned_bin[index] + 1);
    return checksum;
}

export fn subset_sum_bin_packing(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(values[0..length]) orelse -1;
}
