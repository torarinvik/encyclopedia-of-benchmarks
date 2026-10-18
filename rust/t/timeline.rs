const MAX_INITIAL_EVENTS: usize = 16;
const MAX_COMMANDS: usize = 32;
const MAX_EVENTS: usize = MAX_INITIAL_EVENTS + MAX_COMMANDS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 131;
const MAX_OUTPUT_WORDS: usize = 691;
const MAX_OUTPUT_BYTES: usize = 5528;

fn push_word(words: &mut [i64; MAX_OUTPUT_WORDS], count: &mut usize, value: i64) {
    words[*count] = value;
    *count += 1;
}

#[no_mangle]
pub unsafe extern "C" fn timeline(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !(0..=MAX_INITIAL_EVENTS as i64).contains(&values[0]) { return -1; }
    let initial_count = values[0] as usize;
    let command_count_index = 1 + 2 * initial_count;
    if command_count_index >= input_length || !(0..=MAX_COMMANDS as i64).contains(&values[command_count_index]) { return -1; }
    let command_count = values[command_count_index] as usize;
    if input_length != 2 + 2 * initial_count + 3 * command_count { return -1; }

    let mut event_times = [0_i64; MAX_EVENTS];
    let mut event_values = [0_i64; MAX_EVENTS];
    let mut operations = [0_i64; MAX_COMMANDS];
    let mut first_arguments = [0_i64; MAX_COMMANDS];
    let mut second_arguments = [0_i64; MAX_COMMANDS];
    let mut event_count = initial_count;
    for index in 0..initial_count {
        let time = values[1 + 2 * index];
        let value = values[2 + 2 * index];
        if !(0..=1_000_000).contains(&time) || !(-32..=32).contains(&value) { return -1; }
        event_times[index] = time;
        event_values[index] = value;
    }
    // Stable insertion sort matches the constructor's OrderBy.
    for index in 1..initial_count {
        let time = event_times[index];
        let value = event_values[index];
        let mut position = index;
        while position > 0 && event_times[position - 1] > time {
            event_times[position] = event_times[position - 1];
            event_values[position] = event_values[position - 1];
            position -= 1;
        }
        event_times[position] = time;
        event_values[position] = value;
    }

    let mut offset = command_count_index + 1;
    for index in 0..command_count {
        let opcode = values[offset];
        let first = values[offset + 1];
        let second = values[offset + 2];
        if !(0..=14).contains(&opcode) { return -1; }
        if opcode <= 2 {
            if !(0..=1_000_000).contains(&first) || !(-32..=32).contains(&second) { return -1; }
        } else if [3, 4, 5, 6, 8].contains(&opcode) {
            if !(0..=1_000_000).contains(&first) || second != 0 { return -1; }
        } else if opcode == 7 || opcode == 9 {
            if !(-32..=32).contains(&first) || second != 0 { return -1; }
        } else if first != 0 || second != 0 { return -1; }
        operations[index] = opcode;
        first_arguments[index] = first;
        second_arguments[index] = second;
        offset += 3;
    }

    let mut words = [0_i64; MAX_OUTPUT_WORDS];
    let mut word_count = 0_usize;
    for command in 0..command_count {
        let opcode = operations[command];
        let first = first_arguments[command];
        let second = second_arguments[command];
        let count_index = word_count + 1;
        push_word(&mut words, &mut word_count, opcode);
        push_word(&mut words, &mut word_count, 0);

        if opcode == 0 {
            event_times[event_count] = first;
            event_values[event_count] = second;
            event_count += 1;
        } else if opcode == 1 {
            let found = (0..event_count).any(|index| event_times[index] == first && event_values[index] == second);
            push_word(&mut words, &mut word_count, if found { 1 } else { 0 });
        } else if opcode == 2 {
            let found = (0..event_count).find(|&index| event_times[index] == first && event_values[index] == second);
            if let Some(index) = found {
                for next in index + 1..event_count {
                    event_times[next - 1] = event_times[next];
                    event_values[next - 1] = event_values[next];
                }
                event_count -= 1;
                push_word(&mut words, &mut word_count, 1);
            } else { push_word(&mut words, &mut word_count, 0); }
        } else if opcode == 3 {
            for index in 0..event_count {
                if event_times[index] == first { push_word(&mut words, &mut word_count, event_values[index]); }
            }
        } else if opcode == 4 || opcode == 5 || opcode == 10 || opcode == 12 {
            let mut unique = [0_i64; MAX_EVENTS];
            let mut unique_count = 0_usize;
            for index in 0..event_count {
                let seen = (0..index).any(|prior| event_times[prior] == event_times[index]);
                if !seen && (opcode == 10 || opcode == 12 ||
                    (opcode == 4 && event_times[index] < first) ||
                    (opcode == 5 && event_times[index] > first)) {
                    unique[unique_count] = event_times[index];
                    unique_count += 1;
                }
            }
            if opcode == 4 || opcode == 5 {
                for index in 1..unique_count {
                    let value = unique[index];
                    let mut position = index;
                    while position > 0 && unique[position - 1] > value {
                        unique[position] = unique[position - 1];
                        position -= 1;
                    }
                    unique[position] = value;
                }
            }
            if opcode == 12 { push_word(&mut words, &mut word_count, unique_count as i64); }
            else { for index in 0..unique_count { push_word(&mut words, &mut word_count, unique[index]); } }
        } else if opcode == 6 || opcode == 7 {
            let by_time = opcode == 6;
            let mut existed = false;
            let mut write = 0_usize;
            for index in 0..event_count {
                let matches = if by_time { event_times[index] == first } else { event_values[index] == first };
                if matches { existed = true; }
                else {
                    event_times[write] = event_times[index];
                    event_values[write] = event_values[index];
                    write += 1;
                }
            }
            event_count = write;
            push_word(&mut words, &mut word_count, if existed { 1 } else { 0 });
        } else if opcode == 8 || opcode == 9 {
            let found = (0..event_count).any(|index|
                if opcode == 8 { event_times[index] == first } else { event_values[index] == first });
            push_word(&mut words, &mut word_count, if found { 1 } else { 0 });
        } else if opcode == 11 {
            for index in 0..event_count { push_word(&mut words, &mut word_count, event_values[index]); }
        } else if opcode == 13 { push_word(&mut words, &mut word_count, event_count as i64); }
        else { event_count = 0; }

        words[count_index] = (word_count - count_index - 1) as i64;
    }

    push_word(&mut words, &mut word_count, -1);
    push_word(&mut words, &mut word_count, event_count as i64);
    for index in 0..event_count {
        push_word(&mut words, &mut word_count, event_times[index]);
        push_word(&mut words, &mut word_count, event_values[index]);
    }
    let output_bytes = word_count * 8;
    if output.is_null() || output_capacity < output_bytes || output_bytes > MAX_OUTPUT_BYTES { return -2; }
    for index in 0..word_count {
        let bytes = words[index].to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(index * 8), 8);
    }
    output_bytes as i64
}
