const BUCKETS: usize = 8;
const WIDTH: usize = 4;
const MAX_OPERATIONS: usize = 32;
const MAX_KICKS: usize = 8;

fn delta(fingerprint: i64) usize {
    return 1 + ((5 * @as(usize, @intCast(fingerprint)) + 3) % 7);
}

fn firstEmpty(table: *const [BUCKETS * WIDTH]i64, bucket: usize) usize {
    for (0..WIDTH) |slot| if (table.*[bucket * WIDTH + slot] == 0) return slot;
    return WIDTH;
}

fn insert(table: *[BUCKETS * WIDTH]i64, primary: usize, fingerprint: i64) bool {
    const alternate = primary ^ delta(fingerprint);
    var empty = firstEmpty(table, primary);
    if (empty < WIDTH) {
        table.*[primary * WIDTH + empty] = fingerprint;
        return true;
    }
    empty = firstEmpty(table, alternate);
    if (empty < WIDTH) {
        table.*[alternate * WIDTH + empty] = fingerprint;
        return true;
    }
    var current = primary;
    var pending = fingerprint;
    for (0..MAX_KICKS) |_| {
        const position = current * WIDTH;
        const old = table.*[position];
        table.*[position] = pending;
        pending = old;
        current ^= delta(pending);
        empty = firstEmpty(table, current);
        if (empty < WIDTH) {
            table.*[current * WIDTH + empty] = pending;
            return true;
        }
    }
    return false;
}

fn writeI64Le(output: [*c]u8, index: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[index * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn cuckoo_filter_operation_trace(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 4 or length > 98) return -1;
    const raw_count = input[0];
    if (raw_count < 1 or raw_count > @as(i64, MAX_OPERATIONS)) return -1;
    const count: usize = @intCast(raw_count);
    if (length != 1 + 3 * count) return -1;
    for (0..count) |operation| {
        const opcode = input[1 + 3 * operation];
        const primary = input[2 + 3 * operation];
        const fingerprint = input[3 + 3 * operation];
        if (opcode < 0 or opcode > 2 or primary < 0 or primary >= @as(i64, BUCKETS) or
            fingerprint < 1 or fingerprint > 15) return -1;
    }
    const required = count * 8;
    if (output == null or capacity < required) return -2;

    var table: [BUCKETS * WIDTH]i64 = @splat(0);
    var statuses: [MAX_OPERATIONS]i64 = @splat(0);
    for (0..count) |operation| {
        const opcode = input[1 + 3 * operation];
        const primary: usize = @intCast(input[2 + 3 * operation]);
        const fingerprint = input[3 + 3 * operation];
        const alternate = primary ^ delta(fingerprint);
        if (opcode == 0) {
            if (!insert(&table, primary, fingerprint)) return -3;
            statuses[operation] = 1;
        } else if (opcode == 1) {
            var found = false;
            for ([_]usize{ primary, alternate }) |bucket| {
                for (0..WIDTH) |slot| if (table[bucket * WIDTH + slot] == fingerprint) { found = true; };
            }
            statuses[operation] = if (found) 1 else 0;
        } else {
            var removed = false;
            for ([_]usize{ primary, alternate }) |bucket| {
                for (0..WIDTH) |slot| {
                    const position = bucket * WIDTH + slot;
                    if (table[position] == fingerprint) {
                        table[position] = 0;
                        removed = true;
                        break;
                    }
                }
                if (removed) break;
            }
            statuses[operation] = if (removed) 1 else 0;
        }
    }
    for (0..count) |operation| writeI64Le(output, operation, statuses[operation]);
    return @intCast(required);
}
