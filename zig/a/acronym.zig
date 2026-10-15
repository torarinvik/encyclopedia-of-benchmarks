const MAX_PHRASE_LENGTH: usize = 79;

export fn acronym(phrase: [*]const i64, length: usize,
                  output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_PHRASE_LENGTH) return -1;
    var required: usize = 0;
    for (0..length) |index| {
        const value = phrase[index];
        if (value < 1 or value > 127) return -1;
        if (value != 32 and (index == 0 or phrase[index - 1] == 32)) required += 1;
    }
    if (output_capacity < required) return -2;
    var written: usize = 0;
    for (0..length) |index| {
        var value = phrase[index];
        if (value != 32 and (index == 0 or phrase[index - 1] == 32)) {
            if (value >= 97 and value <= 122) value -= 32;
            output[written] = @intCast(value);
            written += 1;
        }
    }
    return @intCast(written);
}
