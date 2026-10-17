const MAX_ITEMS: usize = 512;
const MIN_MERGE: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1026;
const HASH_MULTIPLIER: i64 = 1000003;
const HASH_MODULUS: i64 = 1000000007;
const Item = struct { key: i64, id: i64 };

fn binarySort(items: *[MAX_ITEMS]Item, start: usize, end: usize, first_arg: usize) void {
    var first = first_arg;
    if (first >= end or first <= start) first = start + 1;
    while (first < end) : (first += 1) {
        const target = items[first];
        var left = start;
        var right = first;
        while (left < right) {
            const middle = (left + right) >> 1;
            if (target.key < items[middle].key) right = middle else left = middle + 1;
        }
        var cursor = first;
        while (cursor > left) : (cursor -= 1) items[cursor] = items[cursor - 1];
        items[left] = target;
    }
}

fn countRunAndMakeAscending(items: *[MAX_ITEMS]Item, start: usize, length: usize) usize {
    var end = start + 1;
    if (end == length) return 1;
    if (items[end].key < items[start].key) {
        end += 1;
        while (end < length and items[end].key < items[end - 1].key) : (end += 1) {}
        var left = start;
        var right = end - 1;
        while (left < right) {
            const value = items[left];
            items[left] = items[right];
            items[right] = value;
            left += 1;
            right -= 1;
        }
    } else {
        end += 1;
        while (end < length and items[end].key >= items[end - 1].key) : (end += 1) {}
    }
    return end - start;
}

fn minRunLength(total_arg: usize) usize {
    var total = total_arg;
    var remainder: usize = 0;
    while (total >= MIN_MERGE) {
        remainder |= total & 1;
        total >>= 1;
    }
    return total + remainder;
}

fn mergeAt(items: *[MAX_ITEMS]Item, temp: *[MAX_ITEMS]Item,
    run_base: *[85]usize, run_length: *[85]usize, stack_size: *usize, index: usize) void {
    const base_a = run_base[index];
    const len_a = run_length[index];
    const base_b = run_base[index + 1];
    const len_b = run_length[index + 1];
    run_length[index] = len_a + len_b;
    if (index == stack_size.* - 3) {
        run_base[index + 1] = run_base[index + 2];
        run_length[index + 1] = run_length[index + 2];
    }
    stack_size.* -= 1;
    for (0..len_a) |i| temp[i] = items[base_a + i];
    var left: usize = 0;
    var right = base_b;
    var dest = base_a;
    const end_b = base_b + len_b;
    while (left < len_a and right < end_b) {
        if (items[right].key < temp[left].key) {
            items[dest] = items[right];
            right += 1;
        } else {
            items[dest] = temp[left];
            left += 1;
        }
        dest += 1;
    }
    while (left < len_a) : (left += 1) {
        items[dest] = temp[left];
        dest += 1;
    }
}

fn mergeCollapse(items: *[MAX_ITEMS]Item, temp: *[MAX_ITEMS]Item,
    run_base: *[85]usize, run_length: *[85]usize, stack_size: *usize) void {
    while (stack_size.* > 1) {
        var n = stack_size.* - 2;
        if (n > 0 and run_length[n - 1] <= run_length[n] + run_length[n + 1]) {
            if (run_length[n - 1] < run_length[n + 1]) n -= 1;
            mergeAt(items, temp, run_base, run_length, stack_size, n);
        } else if (run_length[n] <= run_length[n + 1]) {
            mergeAt(items, temp, run_base, run_length, stack_size, n);
        } else break;
    }
}

fn timSort(items: *[MAX_ITEMS]Item, length: usize) void {
    if (length < MIN_MERGE) {
        binarySort(items, 0, length, 0);
        return;
    }
    const min_run = minRunLength(length);
    var run_base: [85]usize = @splat(0);
    var run_length: [85]usize = @splat(0);
    var temp: [MAX_ITEMS]Item = undefined;
    var stack_size: usize = 0;
    var start: usize = 0;
    var remaining = length;
    while (remaining > 0) {
        var current_run = countRunAndMakeAscending(items, start, length);
        if (current_run < min_run) {
            const force = @min(min_run, remaining);
            binarySort(items, start, start + force, start + current_run);
            current_run = force;
        }
        run_base[stack_size] = start;
        run_length[stack_size] = current_run;
        stack_size += 1;
        mergeCollapse(items, &temp, &run_base, &run_length, &stack_size);
        start += current_run;
        remaining -= current_run;
    }
    while (stack_size > 1) {
        var n = stack_size - 2;
        if (n > 0 and run_length[n - 1] < run_length[n + 1]) n -= 1;
        mergeAt(items, &temp, &run_base, &run_length, &stack_size, n);
    }
}

export fn tim_sorter_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_ITEMS))) return -1;
    const count: usize = @intCast(input[0]);
    if (length != 1 + 2 * count) return -1;
    var items: [MAX_ITEMS]Item = undefined;
    var seen: [MAX_ITEMS]bool = @splat(false);
    for (0..count) |index| {
        const key = input[1 + 2 * index];
        const id_value = input[2 + 2 * index];
        if (key < -1000 or key > 1000 or id_value < 0 or id_value >= @as(i64, @intCast(count))) return -1;
        const id: usize = @intCast(id_value);
        if (seen[id]) return -1;
        seen[id] = true;
        items[index] = .{ .key = key, .id = id_value };
    }
    timSort(&items, count);
    var checksum: i64 = 0;
    for (0..count) |index| {
        const item = items[index];
        const token = (item.key + 1000) * 513 + item.id + 1;
        checksum = @mod(checksum * HASH_MULTIPLIER + token, HASH_MODULUS);
    }
    return checksum;
}
