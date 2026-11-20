#include <stddef.h>
#include <stdint.h>

#define POLYPHASE_MAX_ITEMS 256
#define POLYPHASE_RUN_SIZE 8
#define POLYPHASE_MAX_RUNS 34

static void polyphase_place_run(
    const int64_t *input, size_t input_length, uint32_t run_index, uint32_t tape,
    int64_t tapes[3][POLYPHASE_MAX_ITEMS],
    uint32_t run_start[3][POLYPHASE_MAX_RUNS],
    uint32_t run_length[3][POLYPHASE_MAX_RUNS],
    uint32_t run_count[3], uint32_t write_offset[3]) {
    const uint32_t slot = run_count[tape]++;
    const uint32_t start = write_offset[tape];
    const size_t source = (size_t)run_index * POLYPHASE_RUN_SIZE;
    size_t length = input_length - source;
    if (length > POLYPHASE_RUN_SIZE) length = POLYPHASE_RUN_SIZE;
    for (size_t i = 0; i < length; ++i) tapes[tape][start + i] = input[source + i];
    for (size_t i = 1; i < length; ++i) {
        const int64_t value = tapes[tape][start + i];
        size_t position = i;
        while (position > 0 && tapes[tape][start + position - 1] > value) {
            tapes[tape][start + position] = tapes[tape][start + position - 1];
            --position;
        }
        tapes[tape][start + position] = value;
    }
    run_start[tape][slot] = start;
    run_length[tape][slot] = (uint32_t)length;
    write_offset[tape] += (uint32_t)length;
}

static void polyphase_place_dummy(
    uint32_t tape, uint32_t run_start[3][POLYPHASE_MAX_RUNS],
    uint32_t run_length[3][POLYPHASE_MAX_RUNS], uint32_t run_count[3],
    const uint32_t write_offset[3]) {
    const uint32_t slot = run_count[tape]++;
    run_start[tape][slot] = write_offset[tape];
    run_length[tape][slot] = 0;
}

static void polyphase_merge_run(
    int64_t tapes[3][POLYPHASE_MAX_ITEMS],
    uint32_t run_start[3][POLYPHASE_MAX_RUNS],
    uint32_t run_length[3][POLYPHASE_MAX_RUNS],
    uint32_t run_count[3], uint32_t read_index[3], uint32_t write_offset[3],
    uint32_t left_tape, uint32_t right_tape, uint32_t output_tape) {
    const uint32_t left_slot = read_index[left_tape]++;
    const uint32_t right_slot = read_index[right_tape]++;
    const uint32_t left_start = run_start[left_tape][left_slot];
    const uint32_t right_start = run_start[right_tape][right_slot];
    const uint32_t left_length = run_length[left_tape][left_slot];
    const uint32_t right_length = run_length[right_tape][right_slot];
    const uint32_t output_slot = run_count[output_tape]++;
    const uint32_t output_start = write_offset[output_tape];
    uint32_t left = 0, right = 0, written = 0;
    while (left < left_length && right < right_length) {
        if (tapes[left_tape][left_start + left] <= tapes[right_tape][right_start + right])
            tapes[output_tape][output_start + written++] = tapes[left_tape][left_start + left++];
        else
            tapes[output_tape][output_start + written++] = tapes[right_tape][right_start + right++];
    }
    while (left < left_length)
        tapes[output_tape][output_start + written++] = tapes[left_tape][left_start + left++];
    while (right < right_length)
        tapes[output_tape][output_start + written++] = tapes[right_tape][right_start + right++];
    run_start[output_tape][output_slot] = output_start;
    run_length[output_tape][output_slot] = written;
    write_offset[output_tape] += written;
}

void polyphase_merge_sort(int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > POLYPHASE_MAX_ITEMS) return;

    int64_t tapes[3][POLYPHASE_MAX_ITEMS];
    uint32_t run_start[3][POLYPHASE_MAX_RUNS] = {{0}};
    uint32_t run_length[3][POLYPHASE_MAX_RUNS] = {{0}};
    uint32_t run_count[3] = {0, 0, 0};
    uint32_t read_index[3] = {0, 0, 0};
    uint32_t write_offset[3] = {0, 0, 0};

    const uint32_t initial_runs = (uint32_t)((length + POLYPHASE_RUN_SIZE - 1) / POLYPHASE_RUN_SIZE);
    uint32_t quota_a = 1, quota_b = 0;
    while (quota_a + quota_b < initial_runs) {
        const uint32_t next = quota_a + quota_b;
        quota_b = quota_a;
        quota_a = next;
    }
    uint32_t run = 0;
    for (uint32_t slot = 0; slot < quota_a; ++slot, ++run) {
        if (run < initial_runs) polyphase_place_run(values, length, run, 0, tapes, run_start, run_length, run_count, write_offset);
        else polyphase_place_dummy(0, run_start, run_length, run_count, write_offset);
    }
    for (uint32_t slot = 0; slot < quota_b; ++slot, ++run) {
        if (run < initial_runs) polyphase_place_run(values, length, run, 1, tapes, run_start, run_length, run_count, write_offset);
        else polyphase_place_dummy(1, run_start, run_length, run_count, write_offset);
    }

    uint32_t input_a = 0, input_b = 1, output = 2;
    uint32_t remaining_total = run_count[0] + run_count[1];
    while (remaining_total > 1) {
        const uint32_t available_a = run_count[input_a] - read_index[input_a];
        const uint32_t available_b = run_count[input_b] - read_index[input_b];
        if (available_a == 0 || available_b == 0) break;
        run_count[output] = 0;
        read_index[output] = 0;
        write_offset[output] = 0;
        const uint32_t pairs = available_a < available_b ? available_a : available_b;
        for (uint32_t pair = 0; pair < pairs; ++pair)
            polyphase_merge_run(tapes, run_start, run_length, run_count, read_index,
                                write_offset, input_a, input_b, output);
        remaining_total = (run_count[input_a] - read_index[input_a])
            + (run_count[input_b] - read_index[input_b]) + run_count[output];
        const uint32_t left_a = run_count[input_a] - read_index[input_a];
        const uint32_t left_b = run_count[input_b] - read_index[input_b];
        if (remaining_total <= 1 || (left_a == 0 && left_b == 0)) break;
        if (left_a > 0) {
            const uint32_t exhausted = input_b;
            input_b = output;
            output = exhausted;
        } else {
            const uint32_t exhausted = input_a;
            input_a = output;
            output = exhausted;
        }
    }

    for (uint32_t tape = 0; tape < 3; ++tape) {
        if (read_index[tape] < run_count[tape]) {
            const uint32_t slot = read_index[tape];
            if (run_length[tape][slot] == length) {
                const uint32_t start = run_start[tape][slot];
                for (size_t i = 0; i < length; ++i) values[i] = tapes[tape][start + i];
                return;
            }
        }
    }
}
