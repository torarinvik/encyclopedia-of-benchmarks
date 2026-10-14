#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 256
#define MAX_PAIRS (MAX_VALUES / 2)

static void sort_pairs(int64_t *low, int64_t *high, int64_t *scratch_low,
                       int64_t *scratch_high, size_t count)
{
    for (size_t width = 1; width < count; width *= 2) {
        for (size_t start = 0; start < count; start += width * 2) {
            size_t middle = start + width;
            if (middle > count) middle = count;
            size_t end = middle + width;
            if (end > count) end = count;
            size_t left = start;
            size_t right = middle;
            size_t output = start;
            while (left < middle && right < end) {
                size_t source = low[left] <= low[right] ? left++ : right++;
                scratch_low[output] = low[source];
                scratch_high[output++] = high[source];
            }
            while (left < middle) {
                scratch_low[output] = low[left];
                scratch_high[output++] = high[left++];
            }
            while (right < end) {
                scratch_low[output] = low[right];
                scratch_high[output++] = high[right++];
            }
            for (size_t index = start; index < end; ++index) {
                low[index] = scratch_low[index];
                high[index] = scratch_high[index];
            }
        }
        if (width > count / 2) break;
    }
}

static void binary_insert(int64_t *values, size_t *length, int64_t item)
{
    size_t low = 0;
    size_t high = *length;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (values[middle] < item) low = middle + 1;
        else high = middle;
    }
    for (size_t index = *length; index > low; --index) {
        values[index] = values[index - 1];
    }
    values[low] = item;
    ++*length;
}

void merge_insertion_sort(int64_t *values, size_t length)
{
    if (length > MAX_VALUES) return;
    int64_t pair_low[MAX_PAIRS];
    int64_t pair_high[MAX_PAIRS];
    int64_t scratch_low[MAX_PAIRS];
    int64_t scratch_high[MAX_PAIRS];
    int64_t chain[MAX_VALUES];
    const size_t pair_count = length / 2;

    for (size_t pair = 0; pair < pair_count; ++pair) {
        const int64_t first = values[pair * 2];
        const int64_t second = values[pair * 2 + 1];
        if (first <= second) {
            pair_low[pair] = first;
            pair_high[pair] = second;
        } else {
            pair_low[pair] = second;
            pair_high[pair] = first;
        }
    }
    sort_pairs(pair_low, pair_high, scratch_low, scratch_high, pair_count);

    size_t chain_length = 0;
    for (size_t pair = 0; pair < pair_count; ++pair) {
        chain[chain_length++] = pair_low[pair];
    }
    if (pair_count > 0) chain[chain_length++] = pair_high[pair_count - 1];
    if (length % 2 != 0) binary_insert(chain, &chain_length, values[length - 1]);
    for (size_t pair = 0; pair + 1 < pair_count; ++pair) {
        binary_insert(chain, &chain_length, pair_high[pair]);
    }
    for (size_t index = 0; index < length; ++index) values[index] = chain[index];
}
