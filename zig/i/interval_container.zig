const MAX_OPERATIONS: usize = 24;
const RECORD_WIDTH: usize = 3;
const MAX_INPUT_VALUES: usize = 73;
const MAX_INTERVALS: usize = 25;
const DOMAIN_END: i64 = 32;

const Interval = struct { left: i64 = 0, right: i64 = 0 };

fn addInterval(items: *[MAX_INTERVALS]Interval, count: *usize,
               left_in: i64, right_in: i64) void {
    if (left_in == right_in) return;
    var left = left_in;
    var right = right_in;
    var next: [MAX_INTERVALS]Interval = @splat(.{});
    var out: usize = 0;
    var inserted = false;
    for (items[0..count.*]) |current| {
        if (current.right < left) {
            next[out] = current;
            out += 1;
        } else if (right < current.left) {
            if (!inserted) {
                next[out] = .{ .left = left, .right = right };
                out += 1;
                inserted = true;
            }
            next[out] = current;
            out += 1;
        } else {
            left = @min(left, current.left);
            right = @max(right, current.right);
        }
    }
    if (!inserted) {
        next[out] = .{ .left = left, .right = right };
        out += 1;
    }
    @memcpy(items[0..out], next[0..out]);
    count.* = out;
}

fn removeInterval(items: *[MAX_INTERVALS]Interval, count: *usize,
                  left: i64, right: i64) void {
    if (left == right) return;
    var next: [MAX_INTERVALS + 1]Interval = @splat(.{});
    var out: usize = 0;
    for (items[0..count.*]) |current| {
        if (current.right <= left or current.left >= right) {
            next[out] = current;
            out += 1;
        } else {
            if (current.left < left) {
                next[out] = .{ .left = current.left, .right = left };
                out += 1;
            }
            if (current.right > right) {
                next[out] = .{ .left = right, .right = current.right };
                out += 1;
            }
        }
    }
    @memcpy(items[0..out], next[0..out]);
    count.* = out;
}

fn coveredLength(items: *const [MAX_INTERVALS]Interval, count: usize) i64 {
    var total: i64 = 0;
    for (items[0..count]) |item| total += item.right - item.left;
    return total;
}

fn validInput(input: [*c]const i64, length: usize) ?usize {
    if (input == null or length < 1 or length > MAX_INPUT_VALUES) return null;
    if (input[0] < 0 or input[0] > MAX_OPERATIONS) return null;
    const operation_count: usize = @intCast(input[0]);
    if (length != 1 + operation_count * RECORD_WIDTH) return null;
    for (0..operation_count) |index| {
        const offset = 1 + index * RECORD_WIDTH;
        const opcode = input[offset];
        const left = input[offset + 1];
        const right = input[offset + 2];
        if (opcode < 0 or opcode > 1 or left < 0 or right < left or right > DOMAIN_END)
            return null;
    }
    return operation_count;
}

export fn interval_container(input: [*c]const i64, length: usize) i64 {
    const operation_count = validInput(input, length) orelse return -1;
    var items: [MAX_INTERVALS]Interval = @splat(.{});
    var count: usize = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |index| {
        const offset = 1 + index * RECORD_WIDTH;
        const opcode = input[offset];
        const left = input[offset + 1];
        const right = input[offset + 2];
        if (opcode == 0) addInterval(&items, &count, left, right)
        else removeInterval(&items, &count, left, right);
        checksum += @as(i64, @intCast(index + 1)) * coveredLength(&items, count);
    }
    return checksum;
}
