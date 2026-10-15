module activity_selection;

// Count a maximum set of non-overlapping half-open activities.
fn long activity_selection(long* input, usz length) @export("activity_selection")
{
    if (length == 0 || input[0] < 0 || input[0] > 64) return -1;
    usz count = (usz)input[0];
    usz expected_length = 1 + 2 * count;
    if (length != expected_length) return -1;
    if (count == 0) return 0;
    long[64] starts;
    long[64] finishes;
    for (usz index = 0; index < count; index++) {
        starts[index] = input[1 + 2 * index];
        finishes[index] = input[2 + 2 * index];
        if (starts[index] > finishes[index]) return -1;
    }
    for (usz index = 1; index < count; index++) {
        long start = starts[index];
        long finish = finishes[index];
        usz position = index;
        while (position > 0 && (finishes[position - 1] > finish ||
               (finishes[position - 1] == finish && starts[position - 1] > start))) {
            starts[position] = starts[position - 1];
            finishes[position] = finishes[position - 1];
            position--;
        }
        starts[position] = start;
        finishes[position] = finish;
    }
    long selected = 1;
    long last_finish = finishes[0];
    for (usz index = 1; index < count; index++) {
        if (starts[index] >= last_finish) {
            selected++;
            last_finish = finishes[index];
        }
    }
    return selected;
}
