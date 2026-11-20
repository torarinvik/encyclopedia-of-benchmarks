module segment_union_length_klee;

const usz MAX_N = 64;
const usz MAX_EVENTS = 128;

fn void sift_down(long* events, usz root_start, usz count) {
    usz root = root_start;
    while (root < count / 2) {
        usz child = 2 * root + 1;
        if (child + 1 < count && events[child] < events[child + 1]) child++;
        if (events[root] >= events[child]) break;
        long temporary = events[root]; events[root] = events[child]; events[child] = temporary;
        root = child;
    }
}

fn void heap_sort(long* events, usz count) {
    usz start = count / 2;
    while (start > 0) { start--; sift_down(events, start, count); }
    usz end = count;
    while (end > 1) {
        end--;
        long temporary = events[0]; events[0] = events[end]; events[end] = temporary;
        sift_down(events, 0, end);
    }
}

fn long segment_union_length_klee(long* input, usz length) @export("segment_union_length_klee") {
    if (input == null || length < 1 || length > 130) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 2 * n) return -1;
    long[128] events;
    for (usz i = 0; i < n; i++) {
        long left = input[1 + 2 * i], right = input[2 + 2 * i];
        if (left < -1000 || left > right || right > 1000) return -1;
        events[2 * i] = 2 * (left + 1000);
        events[2 * i + 1] = 2 * (right + 1000) + 1;
    }
    usz event_count = 2 * n;
    if (event_count == 0) return 0;
    heap_sort(&events[0], event_count);
    long active = 0, total = 0, previous = 0;
    usz index = 0;
    while (index < event_count) {
        long coordinate_code = events[index] / 2;
        long coordinate = coordinate_code - 1000;
        if (index > 0 && active > 0) total += coordinate - previous;
        long delta = 0;
        while (index < event_count && events[index] / 2 == coordinate_code) {
            delta += events[index] % 2 == 0 ? 1 : -1;
            index++;
        }
        active += delta;
        previous = coordinate;
    }
    return total;
}
