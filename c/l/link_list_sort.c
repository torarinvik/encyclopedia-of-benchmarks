#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 128
#define MAX_INPUT_LENGTH (2 + MAX_ITEMS)

static void merge_sort(int32_t *items, int32_t *scratch, size_t count) {
    for (size_t width = 1; width < count; width *= 2) {
        for (size_t start = 0; start < count;) {
            size_t middle = start + width;
            if (middle > count) middle = count;
            size_t end = middle + width;
            if (end > count) end = count;
            size_t left = start, right = middle, out = start;
            while (left < middle && right < end) {
                if (items[left] <= items[right]) scratch[out++] = items[left++];
                else scratch[out++] = items[right++];
            }
            while (left < middle) scratch[out++] = items[left++];
            while (right < end) scratch[out++] = items[right++];
            start = end;
        }
        for (size_t i = 0; i < count; ++i) items[i] = scratch[i];
    }
}

static void insertion_sort(int32_t *items, size_t count) {
    for (size_t i = 1; i < count; ++i) {
        int32_t value = items[i];
        size_t j = i;
        while (j > 0 && items[j - 1] > value) {
            items[j] = items[j - 1];
            --j;
        }
        items[j] = value;
    }
}

static void sift_down(int32_t *items, size_t count, size_t root) {
    while (root < count / 2) {
        size_t child = 2 * root + 1;
        if (child + 1 < count && items[child + 1] > items[child]) ++child;
        if (items[root] >= items[child]) return;
        int32_t value = items[root];
        items[root] = items[child];
        items[child] = value;
        root = child;
    }
}

static void heap_sort(int32_t *items, size_t count) {
    for (size_t start = count / 2; start > 0;) {
        --start;
        sift_down(items, count, start);
    }
    for (size_t end = count; end > 1;) {
        --end;
        int32_t value = items[0];
        items[0] = items[end];
        items[end] = value;
        sift_down(items, end, 0);
    }
}

int64_t link_list_sort(const int64_t *input, size_t length,
                       uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t selector = input[0], item_count_value = input[1];
    if (selector < 1 || selector > 3 || item_count_value < 0 || item_count_value > MAX_ITEMS) return -1;
    const size_t item_count = (size_t)item_count_value;
    if (length != 2 + item_count) return -1;

    int32_t items[MAX_ITEMS] = {0};
    int32_t scratch[MAX_ITEMS] = {0};
    for (size_t i = 0; i < item_count; ++i) {
        if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;
        items[i] = (int32_t)input[2 + i];
    }
    if (selector == 1) merge_sort(items, scratch, item_count);
    else if (selector == 2) insertion_sort(items, item_count);
    else heap_sort(items, item_count);

    const size_t required = 4 * item_count;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t i = 0; i < item_count; ++i) {
        const uint32_t bits = (uint32_t)items[i];
        for (size_t byte = 0; byte < 4; ++byte)
            output[4 * i + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)required;
}
