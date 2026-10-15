module average_mode;

fn long average_mode(long* values, usz length) @export("average_mode") {
    if (values == null || length == 0 || length > 64) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] < 0 || values[i] > 1000) return -1;
    }

    long mode = -1;
    usz maximum_count = 0;
    bool tied = false;
    for (usz i = 0; i < length; i++) {
        bool seen = false;
        for (usz before = 0; before < i; before++) {
            if (values[before] == values[i]) { seen = true; break; }
        }
        if (seen) continue;

        usz count = 0;
        for (usz j = 0; j < length; j++) {
            if (values[j] == values[i]) count++;
        }
        if (count > maximum_count) {
            maximum_count = count;
            mode = values[i];
            tied = false;
        } else if (count == maximum_count) {
            tied = true;
        }
    }
    return tied ? -1 : mode;
}
