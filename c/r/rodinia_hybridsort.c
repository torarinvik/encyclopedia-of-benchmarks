/* Rodinia/NVIDIA HybridSort bounded port; complete required notices are in the package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

#define HS_MAX_ITEMS 64
#define HS_BINS 1024

static size_t hs_bucket(float value, float minimum, float span) {
    int index = (int)(((value - minimum) / span) * 1024.0f);
    if (index < 0) index = 0;
    if (index >= HS_BINS) index = HS_BINS - 1;
    return (size_t)index;
}

static void hs_merge_sort(int64_t *items, int64_t *scratch, size_t count) {
    for (size_t width = 1; width < count; width *= 2) {
        for (size_t left = 0; left < count; left += 2 * width) {
            size_t middle = left + width < count ? left + width : count;
            size_t right = left + 2 * width < count ? left + 2 * width : count;
            size_t a = left, b = middle, out = left;
            while (a < middle && b < right) scratch[out++] = items[a] <= items[b] ? items[a++] : items[b++];
            while (a < middle) scratch[out++] = items[a++];
            while (b < right) scratch[out++] = items[b++];
        }
        for (size_t i = 0; i < count; ++i) items[i] = scratch[i];
    }
}

static void hs_put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[offset + b] = (uint8_t)(bits >> (8 * b));
}

int64_t rodinia_hybridsort(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > HS_MAX_ITEMS + 1) return -1;
    if (input[0] < 2 || input[0] > HS_MAX_ITEMS || length != 1 + (size_t)input[0]) return -1;
    const size_t count = (size_t)input[0];
    int64_t items[HS_MAX_ITEMS], scratch[HS_MAX_ITEMS];
    int64_t min_raw = INT64_MAX, max_raw = INT64_MIN;
    for (size_t i = 0; i < count; ++i) {
        const int64_t raw = input[1 + i];
        if (raw < 0 || raw > 1000000 || raw % 1000 != 0) return -1;
        items[i] = raw;
        if (raw < min_raw) min_raw = raw;
        if (raw > max_raw) max_raw = raw;
    }
    if (min_raw == max_raw) return -1;
    const size_t output_bytes = count * 8;
    if (output == NULL || capacity < output_bytes) return -2;

    const float minimum = (float)min_raw / 1000000.0f;
    const float maximum = (float)max_raw / 1000000.0f;
    const float span = maximum - minimum;
    size_t histogram[HS_BINS] = {0}, offsets[HS_BINS + 1] = {0}, next[HS_BINS];
    int64_t scattered[HS_MAX_ITEMS];
    for (size_t i = 0; i < count; ++i) {
        const float value = (float)items[i] / 1000000.0f;
        histogram[hs_bucket(value, minimum, span)]++;
    }
    for (size_t bin = 0; bin < HS_BINS; ++bin) offsets[bin + 1] = offsets[bin] + histogram[bin];
    for (size_t bin = 0; bin < HS_BINS; ++bin) next[bin] = offsets[bin];
    for (size_t i = 0; i < count; ++i) {
        const float value = (float)items[i] / 1000000.0f;
        const size_t bin = hs_bucket(value, minimum, span);
        scattered[next[bin]++] = items[i];
    }
    for (size_t bin = 0; bin < HS_BINS; ++bin) {
        const size_t begin = offsets[bin], bucket_size = offsets[bin + 1] - begin;
        if (bucket_size == 0) continue;
        hs_merge_sort(scattered + begin, scratch, bucket_size);
    }
    for (size_t i = 0; i < count; ++i) hs_put_i64(output, 8 * i, scattered[i]);
    return (int64_t)output_bytes;
}
