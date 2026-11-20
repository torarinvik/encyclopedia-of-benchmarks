const max_domain: usize = 1024;
const max_lists: usize = 16;
const max_words: usize = 16;

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn inverted_list_bitvector_intersection(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 258) return -1;
    const values = input.?;
    const domain_value = values[0];
    const list_count_value = values[1];
    if (domain_value < 1 or domain_value > @as(i64, @intCast(max_domain)) or
        list_count_value < 1 or list_count_value > @as(i64, @intCast(max_lists))) return -1;

    const domain: usize = @intCast(domain_value);
    const list_count: usize = @intCast(list_count_value);
    const words_per_list = (domain + 63) / 64;
    if (length != 2 + list_count * words_per_list) return -1;

    const remainder = domain % 64;
    if (remainder != 0) {
        const shift: u6 = @intCast(remainder);
        const valid_mask = (@as(u64, 1) << shift) - 1;
        for (0..list_count) |list| {
            const final_index = 2 + list * words_per_list + words_per_list - 1;
            const final_word: u64 = @bitCast(values[final_index]);
            if ((final_word & ~valid_mask) != 0) return -1;
        }
    }

    var intersection: [max_words]u64 = @splat(0);
    for (0..words_per_list) |word| {
        var combined = ~@as(u64, 0);
        for (0..list_count) |list| {
            const input_index = 2 + list * words_per_list + word;
            combined &= @bitCast(values[input_index]);
        }
        intersection[word] = combined;
    }

    var results: [max_domain]i64 = @splat(0);
    var result_count: usize = 0;
    for (0..domain) |document_id| {
        const shift: u6 = @intCast(document_id % 64);
        const bit = @as(u64, 1) << shift;
        if ((intersection[document_id / 64] & bit) != 0) {
            results[result_count] = @intCast(document_id);
            result_count += 1;
        }
    }

    const output_bytes = (result_count + 1) * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    const output_slice = output.?[0..output_bytes];
    writeI64Le(output_slice, 0, @intCast(result_count));
    for (0..result_count) |index| {
        writeI64Le(output_slice, (index + 1) * 8, results[index]);
    }
    return @intCast(output_bytes);
}
