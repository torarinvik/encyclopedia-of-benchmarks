/// Interpret a bounded Brainfuck byte program with portable limits.
pub export fn brainfuck(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    const max_program = 2048;
    const max_input = 1024;
    const max_output = 8192;
    const max_steps = 100000;
    const tape_cells = 257;

    if (length < 2 or length > max_program + max_input + 2) return -2;
    if (values[0] < 0 or values[0] > max_program) return -2;
    const program_length: usize = @intCast(values[0]);
    const input_length_index = program_length + 1;
    if (input_length_index >= length or values[input_length_index] < 0
        or values[input_length_index] > max_input) return -2;
    const input_length: usize = @intCast(values[input_length_index]);
    if (length != program_length + input_length + 2) return -2;

    var matching: [max_program]i32 = @splat(-1);
    var openings: [max_program]usize = undefined;
    for (0..program_length) |index| {
        const byte = values[index + 1];
        if (byte < 32 or byte > 126) return -2;
    }
    var depth: usize = 0;
    for (0..program_length) |index| {
        const byte = values[index + 1];
        if (byte == '[') {
            openings[depth] = index;
            depth += 1;
        } else if (byte == ']') {
            if (depth == 0) return -2;
            depth -= 1;
            const opening = openings[depth];
            matching[opening] = @intCast(index);
            matching[index] = @intCast(opening);
        }
    }
    if (depth != 0) return -2;
    for (0..input_length) |index| {
        const byte = values[input_length_index + 1 + index];
        if (byte < 0 or byte > 255) return -2;
    }

    var tape: [tape_cells]u8 = @splat(0);
    var scratch: [max_output]u8 = undefined;
    var data_pointer: usize = tape_cells / 2;
    var input_index: usize = 0;
    var instruction: usize = 0;
    var steps: usize = 0;
    var output_length: usize = 0;
    while (instruction < program_length) {
        steps += 1;
        if (steps > max_steps) return -2;
        const command = values[instruction + 1];
        if (command == '.') {
            if (output_length == max_output) return -2;
            scratch[output_length] = tape[data_pointer];
            output_length += 1;
        } else if (command == ',') {
            if (input_index < input_length) {
                tape[data_pointer] = @intCast(values[input_length_index + 1 + input_index]);
                input_index += 1;
            } else {
                tape[data_pointer] = 0;
            }
        } else if (command == '>') {
            data_pointer += 1;
            if (data_pointer >= tape_cells) return -2;
        } else if (command == '<') {
            if (data_pointer == 0) return -2;
            data_pointer -= 1;
        } else if (command == '+') {
            tape[data_pointer] +%= 1;
        } else if (command == '-') {
            tape[data_pointer] -%= 1;
        } else if (command == '[' and tape[data_pointer] == 0) {
            instruction = @intCast(matching[instruction]);
        } else if (command == ']' and tape[data_pointer] != 0) {
            instruction = @intCast(matching[instruction]);
        }
        instruction += 1;
    }
    if (output_length > output_capacity) return -2;
    for (0..output_length) |index| output[index] = scratch[index];
    return @intCast(output_length);
}
