const MAX_OPERATIONS: usize = 512;
const MAX_COLLECTION_SIZE: usize = 256;
const MAX_VALID_INPUT_LENGTH: usize = 1024;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1025;

const SearchResult = struct { index: usize, found: bool };

fn searchPosition(values: *const [MAX_COLLECTION_SIZE]i64, count: usize, target: i64) SearchResult {
    var left: usize = 0;
    var right = count;
    while (right > left) {
        const middle = (left + right) / 2;
        if (target > values[middle]) left = middle + 1
        else if (target < values[middle]) right = middle
        else return .{ .index = middle, .found = true };
    }
    return .{ .index = left, .found = false };
}

export fn sorted_list_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null) return if (length == 0) 0 else -1;
    if (length > MAX_PARSEABLE_INPUT_LENGTH or length % 2 != 0 or length > MAX_VALID_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const operation_count = length / 2;
    if (operation_count > MAX_OPERATIONS) return -1;
    var values: [MAX_COLLECTION_SIZE]i64 = @splat(0);
    var count: usize = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const opcode = input[2 * operation];
        const payload = input[2 * operation + 1];
        if (opcode < 0 or opcode > 5) return -1;
        if (opcode == 0) {
            if (payload < 0 or payload > 1_000_000 or count >= MAX_COLLECTION_SIZE) return -1;
            const result = searchPosition(&values, count, payload);
            var index = count;
            while (index > result.index) : (index -= 1) values[index] = values[index - 1];
            values[result.index] = payload;
            count += 1;
        } else if (opcode == 1 or opcode == 2) {
            if (payload < 0 or payload > 1_000_000) return -1;
            const result = searchPosition(&values, count, payload);
            const observed: i64 = if (result.found) 1 else 0;
            if (opcode == 2 and result.found) {
                for (result.index..count - 1) |index| values[index] = values[index + 1];
                count -= 1;
            }
            checksum += (@as(i64, @intCast(operation)) + 1) * (observed + 1_000_000);
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            checksum += (@as(i64, @intCast(operation)) + 1) * (@as(i64, @intCast(count)) + 1_000_000);
        } else if (opcode == 4) {
            if (payload < 0 or payload >= @as(i64, @intCast(count))) return -1;
            checksum += (@as(i64, @intCast(operation)) + 1) * (values[@intCast(payload)] + 1_000_000);
        } else {
            if (payload != 0) return -1;
            count = 0;
        }
    }
    for (0..count) |index| {
        checksum += (@as(i64, @intCast(operation_count + index)) + 1) * (values[index] + 1_000_000);
    }
    return checksum;
}
