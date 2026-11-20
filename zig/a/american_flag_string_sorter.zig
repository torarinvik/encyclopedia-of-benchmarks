const MAX_STRINGS: usize = 256;
const MAX_STRING_LENGTH: usize = 32;
const MAX_PARSEABLE: usize = 8450;
const BUCKET_COUNT: usize = 257;

fn symbolAt(bytes: []const u8, lengths: []const usize, record: usize, depth: usize) usize {
    if (depth == lengths[record]) return 0;
    return @as(usize, bytes[record * MAX_STRING_LENGTH + depth]) + 1;
}

fn americanFlagSort(bytes: []const u8, lengths: []const usize, order: []usize,
        lo: usize, hi: usize, depth: usize) void {
    if (hi - lo < 2) return;

    var counts = [_]usize{0} ** BUCKET_COUNT;
    for (lo..hi) |position| {
        counts[symbolAt(bytes, lengths, order[position], depth)] += 1;
    }

    var starts = [_]usize{0} ** (BUCKET_COUNT + 1);
    var next = [_]usize{0} ** BUCKET_COUNT;
    starts[0] = lo;
    for (0..BUCKET_COUNT) |bucket| {
        starts[bucket + 1] = starts[bucket] + counts[bucket];
        next[bucket] = starts[bucket];
    }

    for (0..BUCKET_COUNT) |bucket| {
        while (next[bucket] < starts[bucket + 1]) {
            const position = next[bucket];
            const destination_bucket = symbolAt(bytes, lengths, order[position], depth);
            if (destination_bucket == bucket) {
                next[bucket] += 1;
            } else {
                const destination = next[destination_bucket];
                const temporary = order[position];
                order[position] = order[destination];
                order[destination] = temporary;
                next[destination_bucket] += 1;
            }
        }
    }

    for (1..BUCKET_COUNT) |bucket| {
        if (counts[bucket] > 1) {
            americanFlagSort(bytes, lengths, order, starts[bucket], starts[bucket + 1], depth + 1);
        }
    }
}

export fn american_flag_string_sorter(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE) return -1;
    const input = input_opt.?;
    const string_count_value = input[0];
    if (string_count_value < 0 or string_count_value > 256) return -1;
    const string_count: usize = @intCast(string_count_value);

    var bytes = [_]u8{0} ** (MAX_STRINGS * MAX_STRING_LENGTH);
    var string_lengths = [_]usize{0} ** MAX_STRINGS;
    var position: usize = 1;
    for (0..string_count) |record| {
        if (position >= length) return -1;
        const string_length_value = input[position];
        position += 1;
        if (string_length_value < 0 or string_length_value > 32) return -1;
        const string_length: usize = @intCast(string_length_value);
        if (string_length > length - position) return -1;
        string_lengths[record] = string_length;
        for (0..string_length) |byte_index| {
            const byte = input[position];
            position += 1;
            if (byte < 0 or byte > 255) return -1;
            bytes[record * MAX_STRING_LENGTH + byte_index] = @intCast(byte);
        }
    }
    if (position != length) return -1;

    var order = [_]usize{0} ** MAX_STRINGS;
    for (0..string_count) |index| order[index] = index;
    americanFlagSort(bytes[0..], string_lengths[0..], order[0..string_count], 0, string_count, 0);

    var checksum: i64 = 0;
    for (0..string_count) |rank| {
        const record = order[rank];
        var contribution: i64 = @as(i64, @intCast(string_lengths[record])) + 1;
        for (0..string_lengths[record]) |byte_index| {
            contribution += @as(i64, bytes[record * MAX_STRING_LENGTH + byte_index]) + 1;
        }
        checksum += @as(i64, @intCast(rank + 1)) * contribution;
    }
    return checksum;
}
