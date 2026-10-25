/* Rodinia DWT2D (Jiri Matela, Martin Jirman); complete notices in
   benchmarks/r/rodinia_dwt2d/LICENSE.txt. Independent scalar 5/3 lifting port. */
#include <stddef.h>
#include <stdint.h>

#define DWT_MAX_SIDE 16
#define DWT_MAX_CELLS (DWT_MAX_SIDE * DWT_MAX_SIDE)
#define DWT_MAX_INPUT (3 + DWT_MAX_CELLS)

static int64_t dwt_div_trunc(int64_t numerator, int64_t denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}

static void dwt_transform_line(const int64_t *line, int n, int64_t *result) {
    int half = n / 2;
    int64_t detail[DWT_MAX_SIDE / 2];
    for (int j = 0; j < half; ++j) {
        int64_t even = line[2 * j];
        int64_t right = (j + 1 < half) ? line[2 * j + 2] : even;
        detail[j] = line[2 * j + 1] - dwt_div_trunc(even + right, 2);
    }
    result[0] = line[0] + dwt_div_trunc(detail[0] + detail[0] + 2, 4);
    for (int j = 1; j < half; ++j)
        result[j] = line[2 * j] + dwt_div_trunc(detail[j - 1] + detail[j] + 2, 4);
    for (int j = 0; j < half; ++j)
        result[half + j] = detail[j];
}

static void dwt_put_i32_le(uint8_t *out, size_t offset, int64_t value) {
    uint32_t bits = (uint32_t)(int32_t)value;
    for (unsigned byte = 0; byte < 4; ++byte)
        out[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t rodinia_dwt2d(const int64_t *values, size_t length,
                      uint8_t *output, size_t capacity) {
    if (values == NULL || length < 3 || length > DWT_MAX_INPUT) return -1;
    int64_t wi = values[0], hi = values[1], li = values[2];
    if (wi < 2 || wi > DWT_MAX_SIDE || hi < 2 || hi > DWT_MAX_SIDE ||
        li < 1 || li > 3) return -1;
    int factor = 1 << (int)li;
    if (wi < factor || hi < factor || wi % factor != 0 || hi % factor != 0)
        return -1;
    size_t width = (size_t)wi, height = (size_t)hi;
    size_t cells = width * height;
    if (length != 3 + cells) return -1;
    for (size_t i = 0; i < cells; ++i)
        if (values[3 + i] < 0 || values[3 + i] > 255) return -1;
    size_t output_bytes = cells * 4;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t plane[DWT_MAX_CELLS], vertical[DWT_MAX_CELLS], next[DWT_MAX_CELLS];
    int64_t ordered[DWT_MAX_CELLS];
    int64_t line[DWT_MAX_SIDE], transformed[DWT_MAX_SIDE];
    for (size_t i = 0; i < cells; ++i) plane[i] = values[3 + i] - 128;

    size_t active_width = width, active_height = height;
    for (int level = 0; level < (int)li; ++level) {
        for (size_t x = 0; x < active_width; ++x) {
            for (size_t y = 0; y < active_height; ++y)
                line[y] = plane[y * width + x];
            dwt_transform_line(line, (int)active_height, transformed);
            for (size_t y = 0; y < active_height; ++y)
                vertical[y * width + x] = transformed[y];
        }
        for (size_t y = 0; y < active_height; ++y) {
            for (size_t x = 0; x < active_width; ++x)
                line[x] = vertical[y * width + x];
            dwt_transform_line(line, (int)active_width, transformed);
            for (size_t x = 0; x < active_width; ++x)
                next[y * width + x] = transformed[x];
        }
        for (size_t y = 0; y < active_height; ++y)
            for (size_t x = 0; x < active_width; ++x)
                plane[y * width + x] = next[y * width + x];
        active_width /= 2;
        active_height /= 2;
    }
    size_t output_index = 0;
    for (int stage = (int)li - 1; stage >= 0; --stage) {
        size_t stage_width = width >> stage, stage_height = height >> stage;
        size_t half_width = stage_width / 2, half_height = stage_height / 2;
        if (stage == (int)li - 1)
            for (size_t y = 0; y < half_height; ++y)
                for (size_t x = 0; x < half_width; ++x)
                    ordered[output_index++] = plane[y * width + x];
        for (size_t y = 0; y < half_height; ++y)
            for (size_t x = half_width; x < stage_width; ++x)
                ordered[output_index++] = plane[y * width + x];
        for (size_t y = half_height; y < stage_height; ++y)
            for (size_t x = 0; x < half_width; ++x)
                ordered[output_index++] = plane[y * width + x];
        for (size_t y = half_height; y < stage_height; ++y)
            for (size_t x = half_width; x < stage_width; ++x)
                ordered[output_index++] = plane[y * width + x];
    }
    for (size_t i = 0; i < cells; ++i) dwt_put_i32_le(output, 4 * i, ordered[i]);
    return (int64_t)output_bytes;
}
