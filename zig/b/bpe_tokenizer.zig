/// Apply bounded byte-pair merges with first-seen tie-breaking.
pub export fn bpe_tokenizer(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 515) return -2;
    const merge_count_value = values[0];
    const byte_count_value = values[1];
    if (merge_count_value < 0 or merge_count_value > 32
        or byte_count_value < 0 or byte_count_value > 512) return -2;
    const byte_count: usize = @intCast(byte_count_value);
    if (length != byte_count + 2) return -2;
    var tokens: [512]i64 = @splat(0);
    var next_tokens: [512]i64 = @splat(0);
    for (0..byte_count) |index| {
        if (values[index + 2] < 0 or values[index + 2] > 255) return -2;
        tokens[index] = values[index + 2];
    }
    var token_count = byte_count;
    const merge_count: usize = @intCast(merge_count_value);
    for (0..merge_count) |step| {
        if (token_count <= 1) break;
        var pair_left: [511]i64 = @splat(0);
        var pair_right: [511]i64 = @splat(0);
        var pair_frequency: [511]i64 = @splat(0);
        var unique_pairs: usize = 0;
        for (0..token_count - 1) |index| {
            var pair_index: usize = 0;
            while (pair_index < unique_pairs and (pair_left[pair_index] != tokens[index]
                or pair_right[pair_index] != tokens[index + 1])) : (pair_index += 1) {}
            if (pair_index == unique_pairs) {
                pair_left[pair_index] = tokens[index];
                pair_right[pair_index] = tokens[index + 1];
                pair_frequency[pair_index] = 1;
                unique_pairs += 1;
            } else {
                pair_frequency[pair_index] += 1;
            }
        }
        if (unique_pairs == 0) break;
        var best: usize = 0;
        for (1..unique_pairs) |index| {
            if (pair_frequency[index] > pair_frequency[best]) best = index;
        }
        if (pair_frequency[best] == 1) break;
        var next_count: usize = 0;
        var index: usize = 0;
        while (index < token_count) {
            if (index + 1 < token_count and tokens[index] == pair_left[best]
                and tokens[index + 1] == pair_right[best]) {
                next_tokens[next_count] = 256 + @as(i64, @intCast(step));
                next_count += 1;
                index += 2;
            } else {
                next_tokens[next_count] = tokens[index];
                next_count += 1;
                index += 1;
            }
        }
        @memcpy(tokens[0..next_count], next_tokens[0..next_count]);
        token_count = next_count;
    }
    if (token_count > output_capacity / 2) return -2;
    for (0..token_count) |index| {
        const token: u16 = @intCast(tokens[index]);
        output[2 * index] = @truncate(token);
        output[2 * index + 1] = @truncate(token >> 8);
    }
    return @intCast(token_count);
}
