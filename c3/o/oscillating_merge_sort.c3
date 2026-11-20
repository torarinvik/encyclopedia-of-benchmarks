module oscillating_merge_sort;

const usz MAX_VALUES = 1024;
const usz MAX_PARTS = 2;
const usz INITIAL_RUN_SIZE = 16;

fn usz build_run(long* values, usz value_count, usz run_size, usz merge_inputs,
                usz first_run, usz run_count, bool ascending, long* output) {
    if (run_count == 1) {
        usz start = first_run * run_size;
        usz length = value_count - start;
        if (length > run_size) length = run_size;
        for (usz i = 0; i < length; i++) output[i] = values[start + i];
        for (usz i = 1; i < length; i++) {
            long value = output[i];
            usz position = i;
            while (position > 0 && (ascending ? value < output[position - 1]
                                               : value > output[position - 1])) {
                output[position] = output[position - 1];
                position--;
            }
            output[position] = value;
        }
        return length;
    }

    long[MAX_PARTS][MAX_VALUES] children = {};
    usz[MAX_PARTS] lengths = {};
    usz[MAX_PARTS] positions = {};
    usz quotient = run_count / merge_inputs;
    usz remainder = run_count % merge_inputs;
    usz next_run = first_run;
    usz total = 0;
    for (usz lane = 0; lane < merge_inputs; lane++) {
        usz child_count = quotient + (lane < remainder ? 1 : 0);
        if (child_count == 0) continue;
        lengths[lane] = build_run(values, value_count, run_size, merge_inputs,
                                  next_run, child_count, !ascending, &children[lane][0]);
        next_run += child_count;
        total += lengths[lane];
    }
    for (usz out = 0; out < total; out++) {
        usz best_lane = MAX_PARTS;
        long best_value = 0;
        for (usz lane = 0; lane < merge_inputs; lane++) {
            if (positions[lane] >= lengths[lane]) continue;
            long candidate = children[lane][lengths[lane] - 1 - positions[lane]];
            if (best_lane == MAX_PARTS || (ascending ? candidate < best_value
                                                       : candidate > best_value)) {
                best_lane = lane;
                best_value = candidate;
            }
        }
        output[out] = best_value;
        positions[best_lane]++;
    }
    return total;
}

fn void oscillating_merge_sort(long* values, usz length) @export("oscillating_merge_sort") {
    if (length > MAX_VALUES || (length != 0 && values == null) || length == 0) return;
    long[MAX_VALUES] sorted = {};
    usz run_count = (length + INITIAL_RUN_SIZE - 1) / INITIAL_RUN_SIZE;
    build_run(values, length, INITIAL_RUN_SIZE, MAX_PARTS, 0, run_count, true, &sorted[0]);
    for (usz i = 0; i < length; i++) values[i] = sorted[i];
}
