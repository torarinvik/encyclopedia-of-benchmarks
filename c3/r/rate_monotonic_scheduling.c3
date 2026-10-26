module rate_monotonic_scheduling;

const usz MAX_TASKS = 8;
const usz MAX_INPUT = 17;
const usz MAX_OUTPUT_BYTES = 80;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long rate_monotonic_scheduling(long* input, usz length, char* output,
        usz capacity) @export("rate_monotonic_scheduling") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long count_value = input[0];
    if (count_value < 1 || count_value > (long)MAX_TASKS || length != 1 + 2 * (usz)count_value) return -1;
    usz count = (usz)count_value;
    long[MAX_TASKS] execution = zeroed;
    long[MAX_TASKS] period = zeroed;
    usz[MAX_TASKS] order = zeroed;
    long[MAX_TASKS] response = zeroed;
    for (usz task = 0; task < count; task += 1) {
        execution[task] = input[1 + 2 * task];
        period[task] = input[2 + 2 * task];
        if (execution[task] < 1 || execution[task] > 16 || period[task] < 1 || period[task] > 32) return -1;
        order[task] = task;
        response[task] = -1;
    }
    for (usz index = 1; index < count; index += 1) {
        usz key = order[index], position = index;
        while (position > 0 && (period[order[position - 1]] > period[key] ||
            (period[order[position - 1]] == period[key] && order[position - 1] > key))) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = key;
    }

    long schedulable = 1, failed_task = -1;
    for (usz rank = 0; rank < count; rank += 1) {
        usz target = order[rank];
        long remaining_target = execution[target], elapsed = 0;
        long[MAX_TASKS] active = zeroed;
        while (remaining_target > 0 && elapsed < period[target]) {
            for (usz higher_rank = 0; higher_rank < rank; higher_rank += 1) {
                usz higher = order[higher_rank];
                if (elapsed % period[higher] == 0) active[higher] += execution[higher];
            }
            usz selected = MAX_TASKS;
            for (usz higher_rank = 0; higher_rank < rank; higher_rank += 1) {
                usz higher = order[higher_rank];
                if (active[higher] > 0) { selected = higher; break; }
            }
            if (selected < MAX_TASKS) active[selected] -= 1;
            else remaining_target -= 1;
            elapsed += 1;
        }
        if (remaining_target > 0) {
            schedulable = 0;
            failed_task = (long)target;
            break;
        }
        response[target] = elapsed;
    }

    usz output_bytes = 8 * (count + 2);
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    store_i64_le(&staged[0], 0, schedulable);
    store_i64_le(&staged[0], 8, failed_task);
    for (usz task = 0; task < count; task += 1) store_i64_le(&staged[0], 8 * (task + 2), response[task]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return (long)output_bytes;
}
