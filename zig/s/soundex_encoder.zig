const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = MAX_TEXT_LENGTH + 1;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_INPUT_LENGTH + 2;
const MAX_OUTPUT_BYTES: usize = 4;

fn isAsciiLetter(value: i64) bool {
    return (value >= 65 and value <= 90) or (value >= 97 and value <= 122);
}

fn digitFor(input_value: i64) i64 {
    const value = if (input_value >= 65 and input_value <= 90) input_value + 32 else input_value;
    return switch (value) {
        97, 101, 105, 111, 117, 121 => 0,
        104, 119 => 8,
        98, 102, 112, 118 => 1,
        99, 103, 106, 107, 113, 115, 120, 122 => 2,
        100, 116 => 3,
        108 => 4,
        109, 110 => 5,
        114 => 6,
        else => -1,
    };
}

export fn soundex_encoder(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH or values == null) return -1;
    const input = values.?;
    const text_length = input[0];
    if (text_length < 1 or text_length > MAX_TEXT_LENGTH or length > MAX_INPUT_LENGTH or
        length != @as(usize, @intCast(text_length)) + 1) return -1;
    for (1..length) |index| {
        if (!isAsciiLetter(input[index])) return -1;
    }

    var mapped: [MAX_TEXT_LENGTH]i64 = undefined;
    var mapped_count: usize = 0;
    for (1..length) |index| {
        const raw_letter = input[index];
        const letter = if (raw_letter >= 65 and raw_letter <= 90) raw_letter + 32 else raw_letter;
        if (letter == 104 or letter == 119) continue;
        const digit = digitFor(letter);
        if (mapped_count == 0 or mapped[mapped_count - 1] != digit) {
            mapped[mapped_count] = digit;
            mapped_count += 1;
        }
    }

    var code_count: usize = 0;
    for (0..mapped_count) |index| {
        if (mapped[index] != 0) {
            mapped[code_count] = mapped[index];
            code_count += 1;
        }
    }
    if (code_count == 0) return -1;

    const first_letter = if (input[1] >= 65 and input[1] <= 90) input[1] + 32 else input[1];
    var start: usize = 0;
    if (mapped[0] == digitFor(first_letter)) {
        if (code_count == 1) return -1;
        start = 1;
    }

    var encoded: [MAX_OUTPUT_BYTES]u8 = undefined;
    encoded[0] = if (input[1] >= 97 and input[1] <= 122) @intCast(input[1] - 32) else @intCast(input[1]);
    for (0..3) |index| {
        const digit = if (start + index < code_count) mapped[start + index] else 0;
        encoded[index + 1] = @intCast(48 + digit);
    }

    if (output == null or output_capacity < MAX_OUTPUT_BYTES) return -2;
    @memcpy(output.?[0..MAX_OUTPUT_BYTES], encoded[0..MAX_OUTPUT_BYTES]);
    return @intCast(MAX_OUTPUT_BYTES);
}
