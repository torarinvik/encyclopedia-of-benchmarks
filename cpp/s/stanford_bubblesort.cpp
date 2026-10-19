#include <cstddef>
#include <cstdint>

#define MIN_RUNS INT64_C(1)
#define MAX_RUNS INT64_C(100)
#define ELEMENT_COUNT 500
#define MAX_OUTPUT_BYTES 700

static int build_and_sort_pass(int32_t run, int32_t *selected_value) {
    int32_t sortlist[ELEMENT_COUNT + 1];
    int32_t biggest = 0;
    int32_t littlest = 0;
    int64_t seed = 74755;
    for (int32_t i = 1; i <= ELEMENT_COUNT; ++i) {
        seed = (seed * INT64_C(1309) + INT64_C(13849)) & INT64_C(65535);
        const int64_t temp = seed;
        sortlist[i] = (int32_t)(temp - (temp / INT64_C(100000)) * INT64_C(100000) - INT64_C(50000));
        if (sortlist[i] > biggest) biggest = sortlist[i];
        else if (sortlist[i] < littlest) littlest = sortlist[i];
    }
    int32_t top = ELEMENT_COUNT;
    while (top > 1) {
        int32_t i = 1;
        while (i < top) {
            if (sortlist[i] > sortlist[i + 1]) {
                const int32_t temp = sortlist[i];
                sortlist[i] = sortlist[i + 1];
                sortlist[i + 1] = temp;
            }
            ++i;
        }
        --top;
    }
    *selected_value = sortlist[run + 1];
    return sortlist[1] != littlest || sortlist[ELEMENT_COUNT] != biggest;
}

static void append_text(uint8_t *buffer, size_t *used, const char *text) {
    while (*text != '\0') buffer[(*used)++] = (uint8_t)*text++;
}

static void append_integer(uint8_t *buffer, size_t *used, int32_t value) {
    uint8_t reverse[12];
    size_t count = 0;
    int32_t remaining = value;
    if (remaining < 0) { buffer[(*used)++] = (uint8_t)'-'; remaining = -remaining; }
    do {
        reverse[count++] = (uint8_t)('0' + remaining % 10);
        remaining /= 10;
    } while (remaining != 0);
    while (count > 0) buffer[(*used)++] = reverse[--count];
}

extern "C" int64_t stanford_bubblesort(int64_t runs, uint8_t *output, size_t output_capacity) {
    if (runs < MIN_RUNS || runs > MAX_RUNS) return -1;
    if (output == nullptr) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t used = 0;
    for (int32_t run = 0; run < (int32_t)runs; ++run) {
        int32_t selected_value = 0;
        const int endpoint_error = build_and_sort_pass(run, &selected_value);
        if (endpoint_error) append_text(staged, &used, "Error3 in Bubble.\n");
        append_integer(staged, &used, selected_value);
        append_text(staged, &used, "\n");
    }
    if (output_capacity < used) return -2;
    for (size_t i = 0; i < used; ++i) output[i] = staged[i];
    return (int64_t)used;
}
