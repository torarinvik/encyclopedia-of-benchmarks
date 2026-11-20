#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t AVR_MAX_JOBS = 8;
constexpr std::int64_t AVR_MAX_TIME = 8;
constexpr std::size_t AVR_MAX_INPUT = 25;
constexpr std::size_t AVR_MAX_OUTPUT_VALUES = 79;
constexpr std::size_t AVR_MAX_OUTPUT_BYTES = 632;
constexpr std::int64_t AVR_DENSITY_SCALE = 840;

std::int64_t gcd64(std::int64_t a, std::int64_t b) {
    while (b != 0) { const auto r = a % b; a = b; b = r; }
    return a < 0 ? -a : a;
}

void store_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8u * byte));
}
}

extern "C" std::int64_t avr_speed_scaling(const std::int64_t *input, std::size_t length,
                                            std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > AVR_MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(AVR_MAX_JOBS) ||
        length != 1 + 3 * static_cast<std::size_t>(input[0])) return -1;

    const auto jobs = static_cast<std::size_t>(input[0]);
    std::int64_t release[AVR_MAX_JOBS], deadline[AVR_MAX_JOBS];
    std::int64_t changes[AVR_MAX_TIME + 1]{};
    bool points[AVR_MAX_TIME + 1]{};
    std::int64_t remaining[AVR_MAX_JOBS], finish_num[AVR_MAX_JOBS], finish_den[AVR_MAX_JOBS];
    bool finished[AVR_MAX_JOBS]{};

    for (std::size_t j = 0; j < jobs; ++j) {
        const auto r = input[1 + 3 * j];
        const auto d = input[2 + 3 * j];
        const auto w = input[3 + 3 * j];
        if (r < 0 || r >= d || d > AVR_MAX_TIME || w < 1 || w > 8) return -1;
        release[j] = r; deadline[j] = d;
        const auto scaled_density = w * (AVR_DENSITY_SCALE / (d - r));
        changes[r] += scaled_density;
        changes[d] -= scaled_density;
        points[r] = true; points[d] = true;
        remaining[j] = w * AVR_DENSITY_SCALE;
    }

    std::int64_t values[AVR_MAX_OUTPUT_VALUES]{};
    std::size_t segment_count = 0;
    std::int64_t energy_scaled = 0;
    std::int64_t speed_scaled = 0;
    for (std::int64_t start = 0; start < AVR_MAX_TIME; ++start) {
        speed_scaled += changes[start];
        if (!points[start]) continue;
        auto end = start + 1;
        while (end <= AVR_MAX_TIME && !points[end]) ++end;
        if (end > AVR_MAX_TIME || speed_scaled <= 0) continue;

        energy_scaled += speed_scaled * speed_scaled * speed_scaled * (end - start);
        const auto speed_gcd = gcd64(speed_scaled, AVR_DENSITY_SCALE);
        const auto speed_num = speed_scaled / speed_gcd;
        const auto speed_den = AVR_DENSITY_SCALE / speed_gcd;
        if (segment_count > 0) {
            const auto last = 3 + 4 * (segment_count - 1);
            if (values[last + 1] == start && values[last + 2] == speed_num &&
                values[last + 3] == speed_den) {
                values[last + 1] = end;
            } else {
                const auto at = 3 + 4 * segment_count++;
                values[at] = start; values[at + 1] = end;
                values[at + 2] = speed_num; values[at + 3] = speed_den;
            }
        } else {
            const auto at = 3 + 4 * segment_count++;
            values[at] = start; values[at + 1] = end;
            values[at + 2] = speed_num; values[at + 3] = speed_den;
        }

        auto cursor_scaled = start * speed_scaled;
        const auto end_scaled = end * speed_scaled;
        while (cursor_scaled < end_scaled) {
            std::size_t selected = jobs;
            for (std::size_t j = 0; j < jobs; ++j) {
                if (finished[j] || remaining[j] <= 0 || release[j] > start || deadline[j] <= start) continue;
                if (selected == jobs || deadline[j] < deadline[selected]) selected = j;
            }
            if (selected == jobs) break;
            if (cursor_scaled + remaining[selected] <= end_scaled) {
                cursor_scaled += remaining[selected];
                remaining[selected] = 0;
                const auto common = gcd64(cursor_scaled, speed_scaled);
                finish_num[selected] = cursor_scaled / common;
                finish_den[selected] = speed_scaled / common;
                finished[selected] = true;
            } else {
                remaining[selected] -= end_scaled - cursor_scaled;
                cursor_scaled = end_scaled;
            }
        }
    }

    for (std::size_t j = 0; j < jobs; ++j) if (!finished[j]) return -1;
    constexpr auto energy_denominator = AVR_DENSITY_SCALE * AVR_DENSITY_SCALE * AVR_DENSITY_SCALE;
    const auto energy_gcd = gcd64(energy_scaled, energy_denominator);
    const auto segment_end = 3 + 4 * segment_count;
    values[0] = static_cast<std::int64_t>(segment_count);
    values[1] = energy_scaled / energy_gcd;
    values[2] = energy_denominator / energy_gcd;
    auto output_values = segment_end;
    for (std::size_t j = 0; j < jobs; ++j) {
        values[output_values++] = finish_num[j];
        values[output_values++] = finish_den[j];
    }

    const auto output_bytes = 8 * output_values;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[AVR_MAX_OUTPUT_BYTES]{};
    for (std::size_t i = 0; i < output_values; ++i) store_i64(staged, 8 * i, values[i]);
    for (std::size_t i = 0; i < output_bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_bytes);
}
