const MAX_WORDS: usize = 100;
const INVALID_RESULT: i64 = -1;

export fn verifying_an_alien_dictionary(input: [*]const i64, length: usize) i64 {
    if (length < 27 or length > 2127 or input[0] < 1 or input[0] > 100) return INVALID_RESULT;
    const word_count: usize = @intCast(input[0]);
    var rank: [26]i64 = @splat(0);
    var order_seen: [26]bool = @splat(false);
    for (0..26) |position| {
        const letter = input[1 + position];
        if (letter < 'a' or letter > 'z') return INVALID_RESULT;
        const index: usize = @intCast(letter - 'a');
        if (order_seen[index]) return INVALID_RESULT;
        order_seen[index] = true;
        rank[index] = @intCast(position);
    }

    var starts: [MAX_WORDS]usize = @splat(0);
    var word_lengths: [MAX_WORDS]usize = @splat(0);
    var offset: usize = 27;
    for (0..word_count) |word| {
        if (offset >= length or input[offset] < 1 or input[offset] > 20) return INVALID_RESULT;
        const word_length: usize = @intCast(input[offset]);
        offset += 1;
        if (word_length > length - offset) return INVALID_RESULT;
        starts[word] = offset;
        word_lengths[word] = word_length;
        for (0..word_length) |character| {
            const letter = input[offset + character];
            if (letter < 'a' or letter > 'z') return INVALID_RESULT;
        }
        offset += word_length;
    }
    if (offset != length) return INVALID_RESULT;

    for (0..word_count - 1) |word| {
        const left_length = word_lengths[word];
        const right_length = word_lengths[word + 1];
        const limit = @min(left_length, right_length);
        var decided = false;
        for (0..limit) |character| {
            const left_letter: usize = @intCast(input[starts[word] + character] - 'a');
            const right_letter: usize = @intCast(input[starts[word + 1] + character] - 'a');
            if (rank[left_letter] < rank[right_letter]) {
                decided = true;
                break;
            }
            if (rank[left_letter] > rank[right_letter]) return 0;
        }
        if (!decided and left_length > right_length) return 0;
    }
    return 1;
}
