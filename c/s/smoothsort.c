#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 64
#define MAX_INPUT_LENGTH 66

static void swap_i64(int64_t *values, int first, int second)
{
    int64_t temporary = values[first];
    values[first] = values[second];
    values[second] = temporary;
}

static void sift(int64_t *values, int root, int order, const int *leonardo)
{
    while (order > 1) {
        int right = root - 1;
        int left = root - 1 - leonardo[order - 2];
        if (!(values[left] < values[right]) && values[root] < values[left]) {
            swap_i64(values, root, left);
            root = left;
            --order;
        } else if (values[left] < values[right] && values[root] < values[right]) {
            swap_i64(values, root, right);
            root = right;
            order -= 2;
        } else {
            break;
        }
    }
}

static void trinkle(int64_t *values, int position, int *heap_orders, int index,
                    const int *leonardo)
{
    while (index > 0) {
        int previous_root = position - leonardo[heap_orders[index]];
        if (!(values[position] < values[previous_root])) break;
        if (heap_orders[index] > 1) {
            int right = position - 1;
            int left = position - 1 - leonardo[heap_orders[index] - 2];
            if (!(values[right] < values[previous_root]) ||
                !(values[left] < values[previous_root])) break;
        }
        swap_i64(values, position, previous_root);
        position = previous_root;
        --index;
    }
    sift(values, position, heap_orders[index], leonardo);
}

static void smooth_sort(int64_t *values, int count)
{
    if (count < 2) return;
    int leonardo[16] = {1, 1};
    for (int i = 2; i < 16; ++i) leonardo[i] = leonardo[i - 1] + leonardo[i - 2] + 1;
    int heap_orders[MAX_COUNT] = {0};
    int heap_count = 0;
    for (int position = 0; position < count; ++position) {
        if (heap_count >= 2 && heap_orders[heap_count - 2] == heap_orders[heap_count - 1] + 1) {
            --heap_count;
            ++heap_orders[heap_count - 1];
        } else if (heap_count > 0 && heap_orders[heap_count - 1] == 1) {
            heap_orders[heap_count++] = 0;
        } else {
            heap_orders[heap_count++] = 1;
        }
        trinkle(values, position, heap_orders, heap_count - 1, leonardo);
    }
    for (int position = count - 1; position >= 0; --position) {
        int order = heap_orders[--heap_count];
        if (order > 1) {
            int right_order = order - 2;
            int left_order = order - 1;
            int right_position = position - 1;
            int left_position = position - 1 - leonardo[right_order];
            heap_orders[heap_count++] = left_order;
            trinkle(values, left_position, heap_orders, heap_count - 1, leonardo);
            heap_orders[heap_count++] = right_order;
            trinkle(values, right_position, heap_orders, heap_count - 1, leonardo);
        }
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t smoothsort(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > (size_t)MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_COUNT || length != 1 + (size_t)input[0] ||
        length > (size_t)(MAX_COUNT + 1))
        return -1;
    int count = (int)input[0];
    int64_t values[MAX_COUNT];
    for (int i = 0; i < count; ++i) values[i] = input[i + 1];
    smooth_sort(values, count);
    size_t output_bytes = (size_t)count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (int i = 0; i < count; ++i) store_i64_le(output, (size_t)i * 8, values[i]);
    return (int64_t)output_bytes;
}
