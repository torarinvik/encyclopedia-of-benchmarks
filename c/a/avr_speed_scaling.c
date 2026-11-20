#include <stddef.h>
#include <stdint.h>

enum { AVR_MAX_JOBS = 8, AVR_MAX_TIME = 8, AVR_MAX_INPUT = 25,
       AVR_MAX_OUTPUT_VALUES = 79, AVR_MAX_OUTPUT_BYTES = 632,
       AVR_DENSITY_SCALE = 840 };

static int64_t avr_gcd(int64_t a, int64_t b) {
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a < 0 ? -a : a;
}

static void avr_store_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t avr_speed_scaling(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4u || length > AVR_MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > AVR_MAX_JOBS ||
        length != 1u + 3u * (size_t)input[0]) return -1;

    const size_t jobs = (size_t)input[0];
    int64_t release[AVR_MAX_JOBS], deadline[AVR_MAX_JOBS];
    int64_t changes[AVR_MAX_TIME + 1] = {0};
    int points[AVR_MAX_TIME + 1] = {0};
    int64_t remaining[AVR_MAX_JOBS];
    int64_t finish_num[AVR_MAX_JOBS], finish_den[AVR_MAX_JOBS];
    int finished[AVR_MAX_JOBS] = {0};

    for (size_t j = 0; j < jobs; ++j) {
        const int64_t r = input[1u + 3u * j];
        const int64_t d = input[2u + 3u * j];
        const int64_t w = input[3u + 3u * j];
        if (r < 0 || r >= d || d > AVR_MAX_TIME || w < 1 || w > 8) return -1;
        release[j] = r; deadline[j] = d;
        const int64_t scaled_density = w * (AVR_DENSITY_SCALE / (d - r));
        changes[r] += scaled_density;
        changes[d] -= scaled_density;
        points[r] = 1; points[d] = 1;
        remaining[j] = w * AVR_DENSITY_SCALE;
    }

    int64_t values[AVR_MAX_OUTPUT_VALUES] = {0};
    size_t segment_count = 0;
    int64_t energy_scaled = 0;
    int64_t speed_scaled = 0;
    for (int64_t start = 0; start < AVR_MAX_TIME; ++start) {
        speed_scaled += changes[start];
        if (!points[start]) continue;
        int64_t end = start + 1;
        while (end <= AVR_MAX_TIME && !points[end]) ++end;
        if (end > AVR_MAX_TIME || speed_scaled <= 0) continue;

        energy_scaled += speed_scaled * speed_scaled * speed_scaled * (end - start);
        const int64_t speed_gcd = avr_gcd(speed_scaled, AVR_DENSITY_SCALE);
        const int64_t speed_num = speed_scaled / speed_gcd;
        const int64_t speed_den = AVR_DENSITY_SCALE / speed_gcd;
        if (segment_count > 0) {
            const size_t last = 3u + 4u * (segment_count - 1u);
            if (values[last + 1u] == start && values[last + 2u] == speed_num &&
                values[last + 3u] == speed_den) {
                values[last + 1u] = end;
            } else {
                const size_t at = 3u + 4u * segment_count++;
                values[at] = start; values[at + 1u] = end;
                values[at + 2u] = speed_num; values[at + 3u] = speed_den;
            }
        } else {
            const size_t at = 3u + 4u * segment_count++;
            values[at] = start; values[at + 1u] = end;
            values[at + 2u] = speed_num; values[at + 3u] = speed_den;
        }

        int64_t cursor_scaled = start * speed_scaled;
        const int64_t end_scaled = end * speed_scaled;
        while (cursor_scaled < end_scaled) {
            size_t selected = jobs;
            for (size_t j = 0; j < jobs; ++j) {
                if (finished[j] || remaining[j] <= 0 || release[j] > start || deadline[j] <= start) continue;
                if (selected == jobs || deadline[j] < deadline[selected]) selected = j;
            }
            if (selected == jobs) break;
            if (cursor_scaled + remaining[selected] <= end_scaled) {
                cursor_scaled += remaining[selected];
                remaining[selected] = 0;
                const int64_t common = avr_gcd(cursor_scaled, speed_scaled);
                finish_num[selected] = cursor_scaled / common;
                finish_den[selected] = speed_scaled / common;
                finished[selected] = 1;
            } else {
                remaining[selected] -= end_scaled - cursor_scaled;
                cursor_scaled = end_scaled;
            }
        }
    }

    for (size_t j = 0; j < jobs; ++j) if (!finished[j]) return -1;
    const int64_t energy_denominator = (int64_t)AVR_DENSITY_SCALE * AVR_DENSITY_SCALE * AVR_DENSITY_SCALE;
    const int64_t energy_gcd = avr_gcd(energy_scaled, energy_denominator);
    const size_t segment_end = 3u + 4u * segment_count;
    values[0] = (int64_t)segment_count;
    values[1] = energy_scaled / energy_gcd;
    values[2] = energy_denominator / energy_gcd;
    size_t output_values = segment_end;
    for (size_t j = 0; j < jobs; ++j) {
        values[output_values++] = finish_num[j];
        values[output_values++] = finish_den[j];
    }

    const size_t output_bytes = 8u * output_values;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[AVR_MAX_OUTPUT_BYTES] = {0};
    for (size_t i = 0; i < output_values; ++i) avr_store_i64(staged, 8u * i, values[i]);
    for (size_t i = 0; i < output_bytes; ++i) output[i] = staged[i];
    return (int64_t)output_bytes;
}
