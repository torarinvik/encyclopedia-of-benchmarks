module brainfuck;

// Interpret a bounded Brainfuck byte program with portable limits.
fn long brainfuck(long* values, usz length, char* output, usz output_capacity)
    @export("brainfuck")
{
    const usz MAX_PROGRAM = 2048;
    const usz MAX_INPUT = 1024;
    const usz MAX_OUTPUT = 8192;
    const usz MAX_STEPS = 100000;
    const usz TAPE_CELLS = 257;
    if (values == null || length < 2 || length > MAX_PROGRAM + MAX_INPUT + 2) return -2;
    if (values[0] < 0 || values[0] > 2048) return -2;
    usz program_length = (usz)values[0];
    usz input_length_index = program_length + 1;
    if (input_length_index >= length || values[input_length_index] < 0
        || values[input_length_index] > 1024) return -2;
    usz input_length = (usz)values[input_length_index];
    if (length != program_length + input_length + 2) return -2;

    long[2048] matching;
    usz[2048] openings;
    for (usz index = 0; index < program_length; index++) {
        matching[index] = -1;
        long byte = values[index + 1];
        if (byte < 32 || byte > 126) return -2;
    }
    usz depth = 0;
    for (usz index = 0; index < program_length; index++) {
        long byte = values[index + 1];
        if (byte == '[') {
            openings[depth] = index;
            depth++;
        } else if (byte == ']') {
            if (depth == 0) return -2;
            depth--;
            usz opening = openings[depth];
            matching[opening] = (long)index;
            matching[index] = (long)opening;
        }
    }
    if (depth != 0) return -2;
    for (usz index = 0; index < input_length; index++) {
        long byte = values[input_length_index + 1 + index];
        if (byte < 0 || byte > 255) return -2;
    }

    char[257] tape;
    for (usz index = 0; index < TAPE_CELLS; index++) tape[index] = 0;
    char[8192] scratch;
    usz data_pointer = TAPE_CELLS / 2;
    usz input_index = 0;
    usz instruction = 0;
    usz steps = 0;
    usz output_length = 0;
    while (instruction < program_length) {
        steps++;
        if (steps > MAX_STEPS) return -2;
        long command = values[instruction + 1];
        if (command == '.') {
            if (output_length == MAX_OUTPUT) return -2;
            scratch[output_length] = tape[data_pointer];
            output_length++;
        } else if (command == ',') {
            if (input_index < input_length) {
                tape[data_pointer] = (char)values[input_length_index + 1 + input_index];
                input_index++;
            } else {
                tape[data_pointer] = 0;
            }
        } else if (command == '>') {
            data_pointer++;
            if (data_pointer >= TAPE_CELLS) return -2;
        } else if (command == '<') {
            if (data_pointer == 0) return -2;
            data_pointer--;
        } else if (command == '+') {
            tape[data_pointer] = (char)((((usz)tape[data_pointer]) + 1) & 255);
        } else if (command == '-') {
            tape[data_pointer] = (char)((((usz)tape[data_pointer]) - 1) & 255);
        } else if (command == '[' && tape[data_pointer] == 0) {
            instruction = (usz)matching[instruction];
        } else if (command == ']' && tape[data_pointer] != 0) {
            instruction = (usz)matching[instruction];
        }
        instruction++;
    }
    if (output_length > output_capacity || (output_length != 0 && output == null)) return -2;
    for (usz index = 0; index < output_length; index++) output[index] = scratch[index];
    return (long)output_length;
}
