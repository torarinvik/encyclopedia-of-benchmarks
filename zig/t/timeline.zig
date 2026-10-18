const MAX_INITIAL_EVENTS: usize = 16;
const MAX_COMMANDS: usize = 32;
const MAX_EVENTS: usize = 48;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 131;
const MAX_OUTPUT_WORDS: usize = 691;
const MAX_OUTPUT_BYTES: usize = 5528;

fn pushWord(words: *[MAX_OUTPUT_WORDS]i64, count: *usize, value: i64) void {
    words[count.*] = value;
    count.* += 1;
}

export fn timeline(input: [*c]const i64, input_length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 or input[0] > 16) return -1;
    const initial_count: usize = @intCast(input[0]);
    const command_count_index = 1 + 2 * initial_count;
    if (command_count_index >= input_length or input[command_count_index] < 0 or
        input[command_count_index] > 32) return -1;
    const command_count: usize = @intCast(input[command_count_index]);
    if (input_length != 2 + 2 * initial_count + 3 * command_count) return -1;

    var event_times = [_]i64{0} ** MAX_EVENTS;
    var event_values = [_]i64{0} ** MAX_EVENTS;
    var operations = [_]i64{0} ** MAX_COMMANDS;
    var first_arguments = [_]i64{0} ** MAX_COMMANDS;
    var second_arguments = [_]i64{0} ** MAX_COMMANDS;
    var event_count = initial_count;
    for (0..initial_count) |index| {
        const time = input[1 + 2 * index];
        const value = input[2 + 2 * index];
        if (time < 0 or time > 1_000_000 or value < -32 or value > 32) return -1;
        event_times[index] = time;
        event_values[index] = value;
    }
    // Stable insertion sort matches the constructor's OrderBy.
    for (1..initial_count) |index| {
        const time = event_times[index];
        const value = event_values[index];
        var position = index;
        while (position > 0 and event_times[position - 1] > time) {
            event_times[position] = event_times[position - 1];
            event_values[position] = event_values[position - 1];
            position -= 1;
        }
        event_times[position] = time;
        event_values[position] = value;
    }

    var offset = command_count_index + 1;
    for (0..command_count) |index| {
        const opcode = input[offset];
        const first = input[offset + 1];
        const second = input[offset + 2];
        if (opcode < 0 or opcode > 14) return -1;
        if (opcode <= 2) {
            if (first < 0 or first > 1_000_000 or second < -32 or second > 32) return -1;
        } else if (opcode == 3 or opcode == 4 or opcode == 5 or opcode == 6 or opcode == 8) {
            if (first < 0 or first > 1_000_000 or second != 0) return -1;
        } else if (opcode == 7 or opcode == 9) {
            if (first < -32 or first > 32 or second != 0) return -1;
        } else if (first != 0 or second != 0) return -1;
        operations[index] = opcode;
        first_arguments[index] = first;
        second_arguments[index] = second;
        offset += 3;
    }

    var words = [_]i64{0} ** MAX_OUTPUT_WORDS;
    var word_count: usize = 0;
    for (0..command_count) |command| {
        const opcode = operations[command];
        const first = first_arguments[command];
        const second = second_arguments[command];
        const count_index = word_count + 1;
        pushWord(&words, &word_count, opcode);
        pushWord(&words, &word_count, 0);

        if (opcode == 0) {
            event_times[event_count] = first;
            event_values[event_count] = second;
            event_count += 1;
        } else if (opcode == 1) {
            var found = false;
            for (0..event_count) |index| {
                if (event_times[index] == first and event_values[index] == second) found = true;
            }
            pushWord(&words, &word_count, if (found) 1 else 0);
        } else if (opcode == 2) {
            var found = event_count;
            for (0..event_count) |index| {
                if (event_times[index] == first and event_values[index] == second) { found = index; break; }
            }
            if (found < event_count) {
                for (found + 1..event_count) |index| {
                    event_times[index - 1] = event_times[index];
                    event_values[index - 1] = event_values[index];
                }
                event_count -= 1;
                pushWord(&words, &word_count, 1);
            } else pushWord(&words, &word_count, 0);
        } else if (opcode == 3) {
            for (0..event_count) |index| {
                if (event_times[index] == first) pushWord(&words, &word_count, event_values[index]);
            }
        } else if (opcode == 4 or opcode == 5 or opcode == 10 or opcode == 12) {
            var unique = [_]i64{0} ** MAX_EVENTS;
            var unique_count: usize = 0;
            for (0..event_count) |index| {
                var seen = false;
                for (0..index) |prior| {
                    if (event_times[prior] == event_times[index]) seen = true;
                }
                if (!seen and (opcode == 10 or opcode == 12 or
                    (opcode == 4 and event_times[index] < first) or
                    (opcode == 5 and event_times[index] > first))) {
                    unique[unique_count] = event_times[index];
                    unique_count += 1;
                }
            }
            if (opcode == 4 or opcode == 5) {
                for (1..unique_count) |index| {
                    const value = unique[index];
                    var position = index;
                    while (position > 0 and unique[position - 1] > value) {
                        unique[position] = unique[position - 1];
                        position -= 1;
                    }
                    unique[position] = value;
                }
            }
            if (opcode == 12) {
                pushWord(&words, &word_count, @intCast(unique_count));
            } else {
                for (0..unique_count) |index| pushWord(&words, &word_count, unique[index]);
            }
        } else if (opcode == 6 or opcode == 7) {
            const by_time = opcode == 6;
            var existed = false;
            var write: usize = 0;
            for (0..event_count) |index| {
                const matches = if (by_time) event_times[index] == first else event_values[index] == first;
                if (matches) {
                    existed = true;
                } else {
                    event_times[write] = event_times[index];
                    event_values[write] = event_values[index];
                    write += 1;
                }
            }
            event_count = write;
            pushWord(&words, &word_count, if (existed) 1 else 0);
        } else if (opcode == 8 or opcode == 9) {
            var found = false;
            for (0..event_count) |index| {
                if ((opcode == 8 and event_times[index] == first) or
                    (opcode == 9 and event_values[index] == first)) found = true;
            }
            pushWord(&words, &word_count, if (found) 1 else 0);
        } else if (opcode == 11) {
            for (0..event_count) |index| pushWord(&words, &word_count, event_values[index]);
        } else if (opcode == 13) {
            pushWord(&words, &word_count, @intCast(event_count));
        } else {
            event_count = 0;
        }

        words[count_index] = @intCast(word_count - count_index - 1);
    }

    pushWord(&words, &word_count, -1);
    pushWord(&words, &word_count, @intCast(event_count));
    for (0..event_count) |index| {
        pushWord(&words, &word_count, event_times[index]);
        pushWord(&words, &word_count, event_values[index]);
    }
    const output_bytes = word_count * 8;
    if (output == null or capacity < output_bytes or output_bytes > MAX_OUTPUT_BYTES) return -2;
    for (0..word_count) |index| {
        const bits: u64 = @bitCast(words[index]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            output[index * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return @intCast(output_bytes);
}
