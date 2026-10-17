const MAX_INITIAL_KEYS: usize = 128;
const MAX_OPERATIONS: usize = 256;
const MAX_SIZE: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 899;
const MIN_KEY: i64 = -1_000_000;
const MAX_KEY: i64 = 1_000_000;
const HASH_MODULUS: i64 = 1_000_000_007;

fn lowerBound(items: *const [MAX_SIZE]i64, count: usize, key: i64) usize {
    var left: usize = 0;
    var right = count;
    while (left < right) {
        const middle = left + (right - left) / 2;
        if (items[middle] < key) left = middle + 1 else right = middle;
    }
    return left;
}

fn upperBound(items: *const [MAX_SIZE]i64, count: usize, key: i64) usize {
    var left: usize = 0;
    var right = count;
    while (left < right) {
        const middle = left + (right - left) / 2;
        if (items[middle] <= key) left = middle + 1 else right = middle;
    }
    return left;
}

fn keyCode(key: i64) i64 { return key - MIN_KEY + 1; }

fn sequenceCode(items: *const [MAX_SIZE]i64, start: usize, end: usize, descending: bool) i64 {
    var hash: i64 = 0;
    if (descending) {
        var index = end;
        while (index > start) {
            index -= 1;
            hash = @mod(31 * hash + keyCode(items[index]), HASH_MODULUS);
        }
    } else {
        for (start..end) |index| hash = @mod(31 * hash + keyCode(items[index]), HASH_MODULUS);
    }
    return @as(i64, @intCast(end - start)) * HASH_MODULUS + hash;
}

export fn sorted_table_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const initial_value = input[0];
    if (initial_value < 0 or initial_value > MAX_INITIAL_KEYS) return -1;
    const initial_count: usize = @intCast(initial_value);
    const operation_count_index = initial_count + 1;
    if (operation_count_index >= length) return -1;
    const operation_count_value = input[operation_count_index];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    if (length != operation_count_index + 1 + 3 * operation_count or length > 898) return -1;

    var items: [MAX_SIZE]i64 = @splat(0);
    var count = initial_count;
    for (0..initial_count) |index| {
        const key = input[index + 1];
        if (key < MIN_KEY or key > MAX_KEY or (index > 0 and items[index - 1] >= key)) return -1;
        items[index] = key;
    }

    var checksum: i64 = 0;
    const operations_start = operation_count_index + 1;
    for (0..operation_count) |operation| {
        const position = operations_start + 3 * operation;
        const opcode = input[position];
        const first = input[position + 1];
        const second = input[position + 2];
        var observed: i64 = 0;
        var has_result = true;
        if (opcode == 0 or opcode == 1 or opcode == 4 or opcode == 5 or opcode == 7) {
            if (second != 0 or first < MIN_KEY or first > MAX_KEY) return -1;
            const at = lowerBound(&items, count, first);
            const found = at < count and items[at] == first;
            if (opcode == 0) {
                if (found) observed = keyCode(first);
            } else if (opcode == 1) {
                if (found) observed = 1;
            } else if (opcode == 4) {
                const next = if (found) at + 1 else at;
                if (next < count) observed = keyCode(items[next]);
            } else if (opcode == 5) {
                if (at > 0) observed = keyCode(items[at - 1]);
            } else if (found) {
                for (at..count - 1) |index| items[index] = items[index + 1];
                count -= 1;
                observed = keyCode(first);
            }
        } else if (opcode == 2 or opcode == 3) {
            if (first != 0 or second != 0) return -1;
            if (count > 0) observed = keyCode(if (opcode == 2) items[0] else items[count - 1]);
        } else if (opcode == 6) {
            if (first < MIN_KEY or first > MAX_KEY or (second != 0 and second != 1)) return -1;
            const at = lowerBound(&items, count, first);
            if (at < count and items[at] == first) {
                observed = keyCode(items[at]);
            } else {
                if (count >= MAX_SIZE) return -1;
                var index = count;
                while (index > at) {
                    items[index] = items[index - 1];
                    index -= 1;
                }
                items[at] = first;
                count += 1;
            }
        } else if (opcode == 8 or opcode == 9) {
            if (first < MIN_KEY or first > MAX_KEY or second < MIN_KEY or second > MAX_KEY) return -1;
            var start: usize = 0;
            var end: usize = 0;
            if (first <= second) {
                start = lowerBound(&items, count, first);
                end = upperBound(&items, count, second);
            }
            observed = sequenceCode(&items, start, end, opcode == 9);
        } else if (opcode == 10 or opcode == 11) {
            if (first != 0 or second != 0) return -1;
            observed = sequenceCode(&items, 0, count, opcode == 11);
        } else if (opcode == 12) {
            if (first != 0 or second != 0) return -1;
            if (count == 0) observed = 1;
        } else if (opcode == 13) {
            if (first != 0 or second != 0) return -1;
            count = 0;
            has_result = false;
        } else return -1;
        if (has_result) checksum += (@as(i64, @intCast(operation)) + 1) * (observed + 1);
    }
    for (0..count) |index| checksum += (@as(i64, @intCast(operation_count + index)) + 1) * keyCode(items[index]);
    return checksum;
}
