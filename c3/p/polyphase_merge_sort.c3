module polyphase_merge_sort;

const usz MAX_ITEMS = 256;
const usz RUN_SIZE = 8;
const usz MAX_RUNS = 34;

fn void place_run(long* input, usz input_length, uint run_index, uint tape,
                  long[3][256]* tapes, uint[3][34]* starts, uint[3][34]* lengths,
                  uint[3]* counts, uint[3]* write_offsets) {
    uint slot = (*counts)[tape]++;
    uint start = (*write_offsets)[tape];
    usz source = (usz)run_index * RUN_SIZE;
    usz length = input_length - source;
    if (length > RUN_SIZE) length = RUN_SIZE;
    for (usz i = 0; i < length; i++) (*tapes)[tape][start + i] = input[source + i];
    for (usz i = 1; i < length; i++) {
        long value = (*tapes)[tape][start + i];
        usz position = i;
        while (position > 0 && (*tapes)[tape][start + position - 1] > value) {
            (*tapes)[tape][start + position] = (*tapes)[tape][start + position - 1];
            position--;
        }
        (*tapes)[tape][start + position] = value;
    }
    (*starts)[tape][slot] = start;
    (*lengths)[tape][slot] = (uint)length;
    (*write_offsets)[tape] += (uint)length;
}

fn void place_dummy(uint tape, uint[3][34]* starts, uint[3][34]* lengths,
                    uint[3]* counts, uint[3]* write_offsets) {
    uint slot = (*counts)[tape]++;
    (*starts)[tape][slot] = (*write_offsets)[tape];
    (*lengths)[tape][slot] = 0;
}

fn void merge_run(long[3][256]* tapes, uint[3][34]* starts, uint[3][34]* lengths,
                  uint[3]* counts, uint[3]* read_indices, uint[3]* write_offsets,
                  uint left_tape, uint right_tape, uint output_tape) {
    uint left_slot = (*read_indices)[left_tape]++;
    uint right_slot = (*read_indices)[right_tape]++;
    uint left_start = (*starts)[left_tape][left_slot];
    uint right_start = (*starts)[right_tape][right_slot];
    uint left_length = (*lengths)[left_tape][left_slot];
    uint right_length = (*lengths)[right_tape][right_slot];
    uint output_slot = (*counts)[output_tape]++;
    uint output_start = (*write_offsets)[output_tape];
    uint left = 0, right = 0, written = 0;
    while (left < left_length && right < right_length) {
        if ((*tapes)[left_tape][left_start + left] <= (*tapes)[right_tape][right_start + right]) {
            (*tapes)[output_tape][output_start + written] = (*tapes)[left_tape][left_start + left];
            left++;
        } else {
            (*tapes)[output_tape][output_start + written] = (*tapes)[right_tape][right_start + right];
            right++;
        }
        written++;
    }
    while (left < left_length) { (*tapes)[output_tape][output_start + written] = (*tapes)[left_tape][left_start + left]; left++; written++; }
    while (right < right_length) { (*tapes)[output_tape][output_start + written] = (*tapes)[right_tape][right_start + right]; right++; written++; }
    (*starts)[output_tape][output_slot] = output_start;
    (*lengths)[output_tape][output_slot] = written;
    (*write_offsets)[output_tape] += written;
}

fn void polyphase_merge_sort(long* values, usz length) @export("polyphase_merge_sort") {
    if (values == null || length < 2 || length > MAX_ITEMS) return;
    long[3][256] tapes = zeroed;
    uint[3][34] starts = zeroed;
    uint[3][34] run_lengths = zeroed;
    uint[3] counts = zeroed;
    uint[3] read_indices = zeroed;
    uint[3] write_offsets = zeroed;
    uint initial_runs = (uint)((length + RUN_SIZE - 1) / RUN_SIZE);
    uint quota_a = 1, quota_b = 0;
    while (quota_a + quota_b < initial_runs) {
        uint next = quota_a + quota_b;
        quota_b = quota_a;
        quota_a = next;
    }
    uint run = 0;
    for (uint slot = 0; slot < quota_a; slot++) {
        if (run < initial_runs) place_run(values, length, run, 0, &tapes, &starts, &run_lengths, &counts, &write_offsets);
        else place_dummy(0, &starts, &run_lengths, &counts, &write_offsets);
        run++;
    }
    for (uint slot = 0; slot < quota_b; slot++) {
        if (run < initial_runs) place_run(values, length, run, 1, &tapes, &starts, &run_lengths, &counts, &write_offsets);
        else place_dummy(1, &starts, &run_lengths, &counts, &write_offsets);
        run++;
    }
    uint input_a = 0, input_b = 1, output = 2;
    uint remaining_total = counts[0] + counts[1];
    while (remaining_total > 1) {
        uint available_a = counts[input_a] - read_indices[input_a];
        uint available_b = counts[input_b] - read_indices[input_b];
        if (available_a == 0 || available_b == 0) break;
        counts[output] = 0;
        read_indices[output] = 0;
        write_offsets[output] = 0;
        uint pairs = available_a < available_b ? available_a : available_b;
        for (uint pair = 0; pair < pairs; pair++)
            merge_run(&tapes, &starts, &run_lengths, &counts, &read_indices, &write_offsets, input_a, input_b, output);
        uint left_a = counts[input_a] - read_indices[input_a];
        uint left_b = counts[input_b] - read_indices[input_b];
        remaining_total = left_a + left_b + counts[output];
        if (remaining_total <= 1 || (left_a == 0 && left_b == 0)) break;
        if (left_a > 0) {
            uint exhausted = input_b;
            input_b = output;
            output = exhausted;
        } else {
            uint exhausted = input_a;
            input_a = output;
            output = exhausted;
        }
    }
    for (uint tape = 0; tape < 3; tape++) {
        if (read_indices[tape] < counts[tape]) {
            uint slot = read_indices[tape];
            if (run_lengths[tape][slot] == length) {
                uint start = starts[tape][slot];
                for (usz i = 0; i < length; i++) values[i] = tapes[tape][start + i];
                return;
            }
        }
    }
}
