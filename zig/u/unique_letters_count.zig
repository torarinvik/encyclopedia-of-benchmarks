const MAX_TEXT_LENGTH: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_TEXT_LENGTH + 1;
const LETTER_COUNT: usize = 26;
const BYTES_PER_RECORD: usize = 8;

fn storeI32Le(output: [*c]u8, position: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| {
        output[position + byte] = @truncate(bits >> @intCast(byte * 8));
    }
}

export fn unique_letters_count(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input_values = input[0..length];
    if (input_values[0] < 0 or input_values[0] > MAX_TEXT_LENGTH or length != 1 + @as(usize, @intCast(input_values[0]))) return -1;
    const text_length: usize = @intCast(input_values[0]);
    const text = input_values[1..];
    for (text) |byte| if (byte < 0 or byte > 127) return -1;

    var frequencies: [LETTER_COUNT]i32 = @splat(0);
    var first_seen: [LETTER_COUNT]i32 = @splat(0);
    var unique_count: usize = 0;
    for (text) |raw_byte| {
        var byte = raw_byte;
        if (byte >= 65 and byte <= 90) {
            byte += 32;
        } else if (byte < 97 or byte > 122) {
            continue;
        }
        const letter_index: usize = @intCast(byte - 97);
        if (frequencies[letter_index] == 0) {
            first_seen[unique_count] = @intCast(byte);
            unique_count += 1;
        }
        frequencies[letter_index] += 1;
    }

    const required_capacity = @min(text_length, LETTER_COUNT) * BYTES_PER_RECORD;
    if (output_capacity < required_capacity or (required_capacity > 0 and output == null)) return -2;
    for (0..unique_count) |index| {
        const letter = first_seen[index];
        storeI32Le(output, index * BYTES_PER_RECORD, letter);
        storeI32Le(output, index * BYTES_PER_RECORD + 4, frequencies[@intCast(letter - 97)]);
    }
    return @intCast(unique_count);
}
