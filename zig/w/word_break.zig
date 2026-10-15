/// Bottom-up word segmentation over packed lowercase ASCII letter codes.
export fn word_break(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 1122) return -1;
    const text_length_value = values[0];
    const word_count_value = values[1];
    if (text_length_value < 0 or text_length_value > 64 or
        word_count_value < 0 or word_count_value > 32) return -1;
    const text_length: usize = @intCast(text_length_value);
    const word_count: usize = @intCast(word_count_value);
    const dictionary_start = 2 + text_length;
    if (length != dictionary_start + word_count * 33) return -1;
    for (0..text_length) |index| {
        if (values[2 + index] < 1 or values[2 + index] > 26) return -1;
    }
    for (0..word_count) |word| {
        const slot = dictionary_start + word * 33;
        const word_length_value = values[slot];
        if (word_length_value < 1 or word_length_value > 32) return -1;
        const word_length: usize = @intCast(word_length_value);
        for (0..32) |index| {
            const code = values[slot + 1 + index];
            if (index < word_length) {
                if (code < 1 or code > 26) return -1;
            } else if (code != 0) {
                return -1;
            }
        }
    }

    var reachable: [65]bool = @splat(false);
    reachable[0] = true;
    for (0..text_length) |start| {
        if (!reachable[start]) continue;
        for (0..word_count) |word| {
            const slot = dictionary_start + word * 33;
            const word_length: usize = @intCast(values[slot]);
            if (word_length > text_length - start) continue;
            var index: usize = 0;
            while (index < word_length and
                   values[2 + start + index] == values[slot + 1 + index]) : (index += 1) {}
            if (index == word_length) reachable[start + word_length] = true;
        }
    }
    return if (reachable[text_length]) 1 else 0;
}
