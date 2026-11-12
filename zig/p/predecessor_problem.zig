const MAX_N: usize = 4096;
const MAX_WORDS: usize = 64;
const MAX_QUERIES: usize = 512;
const MAX_INPUT_LENGTH: usize = 1090;
const MAX_OUTPUT_BYTES: usize = 4096;

fn findNext(words: []const u64, n: usize, key: usize) i64 {
    const first_word = key / 64;
    for (first_word..words.len) |word| {
        const first_bit = if (word == first_word) key % 64 else 0;
        var candidates = words[word];
        if (first_bit != 0) candidates &= (~@as(u64, 0)) << @intCast(first_bit);
        if (candidates == 0) continue;
        const end_bit = if ((word + 1) * 64 < n) 64 else n - word * 64;
        for (first_bit..end_bit) |bit| {
            if ((candidates >> @intCast(bit)) & 1 != 0) return @intCast(word * 64 + bit);
        }
    }
    return -1;
}

fn findPrevious(words: []const u64, n: usize, key: usize) i64 {
    const first_word = key / 64;
    var word = first_word + 1;
    while (word > 0) {
        word -= 1;
        const valid_bits = if ((word + 1) * 64 > n) n - word * 64 else 64;
        const requested_end = if (word == first_word) key % 64 + 1 else valid_bits;
        const end_bit = @min(requested_end, valid_bits);
        const mask = if (end_bit == 64) ~@as(u64, 0) else (@as(u64, 1) << @intCast(end_bit)) - 1;
        const candidates = words[word] & mask;
        if (candidates == 0) continue;
        var bit = end_bit;
        while (bit > 0) {
            bit -= 1;
            if ((candidates >> @intCast(bit)) & 1 != 0) return @intCast(word * 64 + bit);
        }
    }
    return -1;
}

fn storeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn predecessor_problem(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const n_value = values[0];
    const query_value = values[1];
    if (n_value < 1 or n_value > MAX_N or query_value < 0 or query_value > MAX_QUERIES) return -1;
    const n: usize = @intCast(n_value);
    const queries: usize = @intCast(query_value);
    const word_count = (n + 63) / 64;
    const operation_offset = 2 + word_count;
    if (length != operation_offset + 2 * queries) return -1;
    var words: [MAX_WORDS]u64 = @splat(0);
    for (0..word_count) |word| words[word] = @bitCast(values[2 + word]);
    const tail_bits = n % 64;
    if (tail_bits != 0 and words[word_count - 1] >> @intCast(tail_bits) != 0) return -1;
    for (0..queries) |query| {
        const operation = values[operation_offset + 2 * query];
        const key = values[operation_offset + 2 * query + 1];
        if (operation < 0 or operation > 4 or key < 0 or key >= n_value) return -1;
    }
    var answers: [MAX_QUERIES]i64 = @splat(0);
    var answer_count: usize = 0;
    for (0..queries) |query| {
        const operation = values[operation_offset + 2 * query];
        const key: usize = @intCast(values[operation_offset + 2 * query + 1]);
        const word = key / 64;
        const mask = @as(u64, 1) << @intCast(key % 64);
        if (operation == 0) words[word] |= mask
        else if (operation == 1) words[word] &= ~mask
        else if (operation == 2) {
            answers[answer_count] = if (words[word] & mask != 0) 1 else 0;
            answer_count += 1;
        } else if (operation == 3) {
            answers[answer_count] = findNext(words[0..word_count], n, key);
            answer_count += 1;
        } else {
            answers[answer_count] = findPrevious(words[0..word_count], n, key);
            answer_count += 1;
        }
    }
    const output_bytes = answer_count * 8;
    if (output == null or capacity < output_bytes) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..answer_count) |index| storeI64Le(staged[0..], index * 8, answers[index]);
    const output_slice = output.?[0..output_bytes];
    @memcpy(output_slice, staged[0..output_bytes]);
    return @intCast(output_bytes);
}
