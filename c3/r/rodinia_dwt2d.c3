// Rodinia DWT2D (Jiri Matela, Martin Jirman); complete notices in
// benchmarks/r/rodinia_dwt2d/LICENSE.txt. Independent scalar 5/3 lifting port.
module rodinia_dwt2d;
const usz MAX_SIDE = 16;
const usz MAX_CELLS = 256;
const usz MAX_INPUT = 259;

fn long div_trunc(long numerator, long denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}

fn void transform_line(long* line, int n, long* result) {
    long[8] detail;
    int half = n / 2;
    for (int j = 0; j < half; j += 1) {
        long even = line[2 * j];
        long right = j + 1 < half ? line[2 * j + 2] : even;
        detail[j] = line[2 * j + 1] - div_trunc(even + right, 2);
    }
    result[0] = line[0] + div_trunc(detail[0] + detail[0] + 2, 4);
    for (int j = 1; j < half; j += 1)
        result[j] = line[2 * j] + div_trunc(detail[j - 1] + detail[j] + 2, 4);
    for (int j = 0; j < half; j += 1) result[half + j] = detail[j];
}

fn void put_i32_le(uint8* output, usz offset, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte += 1)
        output[offset + byte] = (uint8)(bits >> (int)(8 * byte));
}

fn long rodinia_dwt2d(long* values, usz length, uint8* output, usz capacity)
    @export("rodinia_dwt2d") {
    if (values == null || length < 3 || length > MAX_INPUT) return -1;
    long wi = values[0], hi = values[1], li = values[2];
    if (wi < 2 || wi > 16 || hi < 2 || hi > 16 || li < 1 || li > 3) return -1;
    long factor = 1 << (int)li;
    if (wi < factor || hi < factor || wi % factor != 0 || hi % factor != 0) return -1;
    usz width = (usz)wi, height = (usz)hi, cells = width * height;
    if (length != 3 + cells) return -1;
    for (usz i = 0; i < cells; i += 1)
        if (values[3 + i] < 0 || values[3 + i] > 255) return -1;
    usz output_bytes = cells * 4;
    if (output == null || capacity < output_bytes) return -2;

    long[256] plane, vertical, next, ordered;
    long[16] line, transformed;
    for (usz i = 0; i < cells; i += 1) plane[i] = values[3 + i] - 128;
    usz active_width = width, active_height = height;
    for (long level = 0; level < li; level += 1) {
        for (usz x = 0; x < active_width; x += 1) {
            for (usz y = 0; y < active_height; y += 1) line[y] = plane[y * width + x];
            transform_line(&line[0], (int)active_height, &transformed[0]);
            for (usz y = 0; y < active_height; y += 1) vertical[y * width + x] = transformed[y];
        }
        for (usz y = 0; y < active_height; y += 1) {
            for (usz x = 0; x < active_width; x += 1) line[x] = vertical[y * width + x];
            transform_line(&line[0], (int)active_width, &transformed[0]);
            for (usz x = 0; x < active_width; x += 1) next[y * width + x] = transformed[x];
        }
        for (usz y = 0; y < active_height; y += 1)
            for (usz x = 0; x < active_width; x += 1) plane[y * width + x] = next[y * width + x];
        active_width /= 2;
        active_height /= 2;
    }
    usz output_index = 0;
    for (int stage = (int)li - 1; stage >= 0; stage -= 1) {
        usz stage_width = width >> stage, stage_height = height >> stage;
        usz half_width = stage_width / 2, half_height = stage_height / 2;
        if (stage == (int)li - 1)
            for (usz y = 0; y < half_height; y += 1)
                for (usz x = 0; x < half_width; x += 1) ordered[output_index++] = plane[y * width + x];
        for (usz y = 0; y < half_height; y += 1)
            for (usz x = half_width; x < stage_width; x += 1) ordered[output_index++] = plane[y * width + x];
        for (usz y = half_height; y < stage_height; y += 1)
            for (usz x = 0; x < half_width; x += 1) ordered[output_index++] = plane[y * width + x];
        for (usz y = half_height; y < stage_height; y += 1)
            for (usz x = half_width; x < stage_width; x += 1) ordered[output_index++] = plane[y * width + x];
    }
    for (usz i = 0; i < cells; i += 1) put_i32_le(output, 4 * i, ordered[i]);
    return (long)output_bytes;
}
