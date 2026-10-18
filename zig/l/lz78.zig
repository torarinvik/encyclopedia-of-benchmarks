const MAX_INPUT_LENGTH: usize = 66;
const MAX_TEXT_LENGTH: usize = 64;
const MAX_OUTPUT_BYTES: usize = 1024;

fn putI64Le(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| {
        const shift: u6 = @intCast(byte_index * 8);
        output[offset + byte_index] = @truncate(bits >> shift);
    }
}

export fn lz78_compress(input: [*c]const i64, input_length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or input_length < 1 or input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > MAX_TEXT_LENGTH) return -1;
    const text_length: usize = @intCast(input[0]);
    if (input_length != 1 + text_length) return -1;
    for (0..text_length) |index| {
        const character = input[index + 1];
        if (character < 32 or character > 126) return -1;
    }

    var edge_parent = [_]i64{0} ** MAX_TEXT_LENGTH;
    var edge_character = [_]i64{0} ** MAX_TEXT_LENGTH;
    var dictionary_size: usize = 0;
    var token_indices = [_]i64{0} ** MAX_TEXT_LENGTH;
    var token_characters = [_]i64{0} ** MAX_TEXT_LENGTH;
    var token_count: usize = 0;
    var current_index: i64 = 0;
    for (0..text_length) |index| {
        const character = input[index + 1];
        var found: ?usize = null;
        for (0..dictionary_size) |edge| {
            if (edge_parent[edge] == current_index and edge_character[edge] == character) {
                found = edge;
                break;
            }
        }
        if (found) |edge| {
            current_index = @intCast(edge + 1);
        } else {
            token_indices[token_count] = current_index;
            token_characters[token_count] = character;
            token_count += 1;
            edge_parent[dictionary_size] = current_index;
            edge_character[dictionary_size] = character;
            dictionary_size += 1;
            current_index = 0;
        }
    }
    if (current_index != 0) {
        token_indices[token_count] = current_index;
        token_characters[token_count] = 0;
        token_count += 1;
    }

    const output_bytes = 16 * token_count;
    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    for (0..token_count) |token| {
        putI64Le(&staged, 16 * token, token_indices[token]);
        putI64Le(&staged, 16 * token + 8, token_characters[token]);
    }
    if (output == null or capacity < output_bytes) return -2;
    if (output_bytes > 0) @memcpy(output[0..output_bytes], staged[0..output_bytes]);
    return @intCast(output_bytes);
}
