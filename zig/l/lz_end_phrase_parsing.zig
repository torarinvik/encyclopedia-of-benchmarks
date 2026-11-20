const MAX_TEXT: usize = 64;
const MAX_INPUT: usize = 66;
const PHRASE_MULTIPLIER: i64 = 133121;

export fn lz_end_phrase_parsing(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 1 or length > MAX_INPUT) return -1;
    const n64 = values[0];
    if (n64 < 0 or n64 > MAX_TEXT or length != @as(usize, @intCast(n64)) + 1) return -1;
    const n: usize = @intCast(n64);
    for (0..n) |i| if (values[1 + i] < 0 or values[1 + i] > 255) return -1;
    var boundaries: [MAX_TEXT]usize = [_]usize{0} ** MAX_TEXT;
    var phrase_lengths: [MAX_TEXT]usize = [_]usize{0} ** MAX_TEXT;
    var phrases: usize = 0;
    var position: usize = 0;
    while (position < n) {
        var best_copy: usize = 0;
        var copy_length = n - position - 1;
        while (copy_length > 0 and best_copy == 0) : (copy_length -= 1) {
            var prior = phrases;
            while (prior > 0 and best_copy == 0) {
                prior -= 1;
                const boundary = boundaries[prior];
                if (boundary < copy_length) continue;
                var matches = true;
                for (0..copy_length) |offset| {
                    if (values[1 + position + offset] != values[1 + boundary - copy_length + offset]) {
                        matches = false;
                        break;
                    }
                }
                if (matches) best_copy = copy_length;
            }
        }
        phrase_lengths[phrases] = best_copy + 1;
        position += phrase_lengths[phrases];
        boundaries[phrases] = position;
        phrases += 1;
    }
    var checksum: i64 = 0;
    for (0..phrases) |i| checksum += @as(i64, @intCast(i + 1)) * @as(i64, @intCast(phrase_lengths[i]));
    return PHRASE_MULTIPLIER * @as(i64, @intCast(phrases)) + checksum;
}
