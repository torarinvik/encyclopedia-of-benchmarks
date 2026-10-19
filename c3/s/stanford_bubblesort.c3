module stanford_bubblesort;

const long MIN_RUNS = 1;
const long MAX_RUNS = 100;
const int ELEMENT_COUNT = 500;
const usz MAX_OUTPUT_BYTES = 700;

fn bool build_and_sort_pass(int run, int* selected_value) {
    int[ELEMENT_COUNT + 1] sortlist;
    long seed = 74755;
    int biggest = 0;
    int littlest = 0;
    for (int i = 1; i <= ELEMENT_COUNT; ++i) {
        seed = (seed * 1309 + 13849) & 65535;
        long temp = seed;
        sortlist[i] = (int)(temp - (temp / 100000) * 100000 - 50000);
        if (sortlist[i] > biggest) biggest = sortlist[i];
        else if (sortlist[i] < littlest) littlest = sortlist[i];
    }
    int top = ELEMENT_COUNT;
    while (top > 1) {
        int i = 1;
        while (i < top) {
            if (sortlist[i] > sortlist[i + 1]) {
                int temp = sortlist[i];
                sortlist[i] = sortlist[i + 1];
                sortlist[i + 1] = temp;
            }
            i++;
        }
        top--;
    }
    *selected_value = sortlist[run + 1];
    return sortlist[1] != littlest || sortlist[ELEMENT_COUNT] != biggest;
}

fn void append_text(char* buffer, usz* used, const char* text) {
    while (*text != '\0') {
        buffer[*used] = *text;
        *used = *used + 1;
        text++;
    }
}

fn void append_integer(char* buffer, usz* used, int value) {
    int remaining = value;
    if (remaining < 0) {
        buffer[*used] = '-';
        *used = *used + 1;
        remaining = -remaining;
    }
    char[12] reverse;
    usz count = 0;
    do {
        reverse[count++] = (char)('0' + remaining % 10);
        remaining /= 10;
    } while (remaining != 0);
    while (count > 0) {
        count--;
        buffer[*used] = reverse[count];
        *used = *used + 1;
    }
}

fn long stanford_bubblesort(long runs, char* output, usz output_capacity)
    @export("stanford_bubblesort") {
    if (runs < MIN_RUNS || runs > MAX_RUNS) return -1;
    if (output == null) return -2;
    char[MAX_OUTPUT_BYTES] staged;
    usz used = 0;
    for (int run = 0; run < (int)runs; ++run) {
        int selected_value = 0;
        bool endpoint_error = build_and_sort_pass(run, &selected_value);
        if (endpoint_error) append_text(&staged[0], &used, "Error3 in Bubble.\n");
        append_integer(&staged[0], &used, selected_value);
        append_text(&staged[0], &used, "\n");
    }
    if (output_capacity < used) return -2;
    for (usz i = 0; i < used; ++i) output[i] = staged[i];
    return (long)used;
}
