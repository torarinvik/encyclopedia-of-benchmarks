module max_jobs_before_deadlines;

const MAX_JOBS = 12;

fn bool before(long left_duration, int left_id, long right_duration, int right_id) {
    return left_duration < right_duration ||
        (left_duration == right_duration && left_id < right_id);
}

fn void heap_push(long* durations, int* ids, usz* size, long duration, int id) {
    usz index = size[0];
    size[0] = size[0] + 1;
    while (index > 0) {
        usz parent = (index - 1) / 2;
        if (!before(duration, id, durations[parent], ids[parent])) break;
        durations[index] = durations[parent];
        ids[index] = ids[parent];
        index = parent;
    }
    durations[index] = duration;
    ids[index] = id;
}

fn void heap_pop(long* durations, int* ids, usz* size, long* result_duration, int* result_id) {
    result_duration[0] = durations[0];
    result_id[0] = ids[0];
    size[0] = size[0] - 1;
    if (size[0] == 0) return;
    long last_duration = durations[size[0]];
    int last_id = ids[size[0]];
    usz index = 0;
    while (2 * index + 1 < size[0]) {
        usz child = 2 * index + 1;
        if (child + 1 < size[0] && before(durations[child + 1], ids[child + 1], durations[child], ids[child])) child++;
        if (!before(durations[child], ids[child], last_duration, last_id)) break;
        durations[index] = durations[child];
        ids[index] = ids[child];
        index = child;
    }
    durations[index] = last_duration;
    ids[index] = last_id;
}

fn long max_jobs_before_deadlines(long* input, usz length) @export("max_jobs_before_deadlines") {
    if (input == null || length < 1 || length > 1 + 2 * MAX_JOBS) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > MAX_JOBS || length != 1 + 2 * (usz)count_value) return -1;
    usz count = (usz)count_value;
    long[MAX_JOBS] deadlines, durations;
    int[MAX_JOBS] ids;
    for (usz i = 0; i < count; i++) {
        long deadline = input[1 + 2 * i], duration = input[2 + 2 * i];
        if (deadline < 0 || deadline > 1000 || duration < 1 || duration > 1000) return -1;
        deadlines[i] = deadline;
        durations[i] = duration;
        ids[i] = (int)i;
    }
    for (usz i = 1; i < count; i++) {
        long deadline = deadlines[i], duration = durations[i];
        int id = ids[i];
        usz position = i;
        while (position > 0 && deadlines[position - 1] > deadline) {
            deadlines[position] = deadlines[position - 1];
            durations[position] = durations[position - 1];
            ids[position] = ids[position - 1];
            position--;
        }
        deadlines[position] = deadline;
        durations[position] = duration;
        ids[position] = id;
    }
    long[MAX_JOBS] heap_durations;
    int[MAX_JOBS] heap_ids;
    usz heap_size = 0;
    long completed = 0;
    usz end = count;
    while (end > 0) {
        end--;
        heap_push(&heap_durations[0], &heap_ids[0], &heap_size, durations[end], ids[end]);
        long lower = end == 0 ? 0 : deadlines[end - 1];
        long interval = deadlines[end] - lower;
        while (interval > 0 && heap_size > 0) {
            long remaining;
            int id;
            heap_pop(&heap_durations[0], &heap_ids[0], &heap_size, &remaining, &id);
            if (remaining <= interval) {
                interval -= remaining;
                completed++;
            } else {
                heap_push(&heap_durations[0], &heap_ids[0], &heap_size, remaining - interval, id);
                interval = 0;
            }
        }
    }
    return completed;
}
