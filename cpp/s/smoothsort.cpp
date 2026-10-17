#include <stddef.h>
#include <stdint.h>

static void sift(int64_t *values, int root, int order, const int *leonardo)
{
    while (order > 1) {
        int right = root - 1;
        int left = root - 1 - leonardo[order - 2];
        if (!(values[left] < values[right]) && values[root] < values[left]) {
            int64_t temporary = values[root]; values[root] = values[left]; values[left] = temporary;
            root = left; --order;
        } else if (values[left] < values[right] && values[root] < values[right]) {
            int64_t temporary = values[root]; values[root] = values[right]; values[right] = temporary;
            root = right; order -= 2;
        } else break;
    }
}
static void trinkle(int64_t *values, int position, int *orders, int index, const int *leonardo)
{
    while (index > 0) {
        int previous = position - leonardo[orders[index]];
        if (!(values[position] < values[previous])) break;
        if (orders[index] > 1) {
            int right = position - 1, left = position - 1 - leonardo[orders[index] - 2];
            if (!(values[right] < values[previous]) || !(values[left] < values[previous])) break;
        }
        int64_t temporary = values[position]; values[position] = values[previous]; values[previous] = temporary;
        position = previous; --index;
    }
    sift(values, position, orders[index], leonardo);
}
static void smooth_sort(int64_t *values, int count)
{
    if (count < 2) return;
    int leonardo[16] = {1, 1};
    for (int i = 2; i < 16; ++i) leonardo[i] = leonardo[i - 1] + leonardo[i - 2] + 1;
    int orders[64] = {0}, heap_count = 0;
    for (int position = 0; position < count; ++position) {
        if (heap_count >= 2 && orders[heap_count - 2] == orders[heap_count - 1] + 1) {
            --heap_count; ++orders[heap_count - 1];
        } else if (heap_count > 0 && orders[heap_count - 1] == 1) orders[heap_count++] = 0;
        else orders[heap_count++] = 1;
        trinkle(values, position, orders, heap_count - 1, leonardo);
    }
    for (int position = count - 1; position >= 0; --position) {
        int order = orders[--heap_count];
        if (order > 1) {
            int right_order = order - 2, left_order = order - 1;
            int right_position = position - 1, left_position = position - 1 - leonardo[right_order];
            orders[heap_count++] = left_order; trinkle(values, left_position, orders, heap_count - 1, leonardo);
            orders[heap_count++] = right_order; trinkle(values, right_position, orders, heap_count - 1, leonardo);
        }
    }
}
static void store_i64(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t smoothsort(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > (size_t)66 || input[0] < 0 || input[0] > 64) return -1;
    int count = (int)input[0];
    if (length != (size_t)(1 + count) || length > (size_t)65) return -1;
    int64_t values[64]; for (int i = 0; i < count; ++i) values[i] = input[i + 1];
    smooth_sort(values, count);
    size_t bytes = (size_t)count * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (int i = 0; i < count; ++i) store_i64(output, (size_t)i * 8, values[i]);
    return (int64_t)bytes;
}
