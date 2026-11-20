#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t list_count = 3;
constexpr std::size_t max_list = 32;
constexpr std::size_t max_values = 48;
constexpr std::size_t max_input = 3 + list_count * max_list;
enum class Color : std::uint8_t { white, green, red };

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}  // namespace

extern "C" std::int64_t t_threshold_three_sorted_lists(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 6 || length > max_input + 1) return -1;
    std::array<std::size_t, list_count> base{}, size{};
    std::size_t at = 0;
    for (std::size_t id = 0; id < list_count; ++id) {
        if (at >= length || input[at] < 1 || input[at] > static_cast<std::int64_t>(max_list)) return -1;
        size[id] = static_cast<std::size_t>(input[at++]);
        if (size[id] > length - at) return -1;
        base[id] = at;
        for (std::size_t j = 0; j < size[id]; ++j) {
            const auto value = input[at + j];
            if (value < INT32_MIN || value > INT32_MAX || (j > 0 && input[at + j - 1] >= value)) return -1;
        }
        at += size[id];
    }
    if (at != length) return -1;

    std::array<std::int64_t, list_count> tails{}, firsts{};
    for (std::size_t i = 0; i < list_count; ++i) {
        tails[i] = input[base[i] + size[i] - 1];
        firsts[i] = input[base[i]];
    }
    std::sort(tails.begin(), tails.end());
    std::sort(firsts.begin(), firsts.end());
    auto candidate = firsts[1];
    const auto maximum_candidate = tails[1];

    std::array<Color, list_count> color{};
    std::array<std::size_t, list_count> cursor{1, 1, 1}, search_base{1, 1, 1},
        search_low{1, 1, 1}, search_step{1, 1, 1}, search_probe{1, 1, 1}, representative{};
    std::array<bool, list_count> representative_present{};
    for (std::size_t i = 0; i < list_count; ++i) {
        if (input[base[i]] == candidate) color[i] = Color::green;
        else if (input[base[i]] > candidate) {
            color[i] = Color::red;
            representative_present[i] = true;
        }
    }

    std::array<std::int64_t, max_values> result{};
    std::size_t result_count = 0, round_robin = 0;
    while (candidate <= maximum_candidate) {
        std::size_t green_count = 0, red_count = 0, white_count = 0;
        for (const auto state : color) {
            if (state == Color::green) ++green_count;
            else if (state == Color::red) ++red_count;
            else ++white_count;
        }
        if (green_count >= 2 || red_count >= 2) {
            if (green_count >= 2) result[result_count++] = candidate;
            std::size_t recolor_count = white_count == 0 ? 1 : 0;
            for (std::size_t i = 0; i < list_count && recolor_count > 0; ++i) {
                if (color[i] != Color::green) continue;
                color[i] = Color::white;
                search_base[i] = search_low[i] = search_probe[i] = cursor[i];
                search_step[i] = 1;
                --recolor_count;
            }
            for (std::size_t i = 0; i < list_count; ++i) {
                if (color[i] != Color::green) continue;
                color[i] = Color::red;
                representative[i] = cursor[i];
                representative_present[i] = cursor[i] < size[i];
            }
            bool found = false;
            std::int64_t next_candidate = INT64_MAX;
            for (std::size_t i = 0; i < list_count; ++i) {
                if (!representative_present[i]) continue;
                const auto value = input[base[i] + representative[i]];
                if (!found || value < next_candidate) { found = true; next_candidate = value; }
            }
            if (!found) break;
            candidate = next_candidate;
            for (std::size_t i = 0; i < list_count; ++i) {
                if (color[i] != Color::red || !representative_present[i] ||
                    input[base[i] + representative[i]] != candidate) continue;
                color[i] = Color::green;
                representative_present[i] = false;
                cursor[i] = representative[i] + 1;
                search_base[i] = search_low[i] = search_probe[i] = cursor[i];
                search_step[i] = 1;
            }
            continue;
        }

        std::size_t list_id = list_count;
        for (std::size_t offset = 0; offset < list_count; ++offset) {
            const auto i = (round_robin + offset) % list_count;
            if (color[i] == Color::white) { list_id = i; break; }
        }
        if (list_id == list_count) break;
        round_robin = (list_id + 1) % list_count;
        const auto probe = std::min(search_probe[list_id], size[list_id] - 1);
        if (input[base[list_id] + probe] < candidate) {
            search_low[list_id] = probe + 1;
            if (probe + 1 == size[list_id]) {
                color[list_id] = Color::red;
                representative[list_id] = size[list_id];
                representative_present[list_id] = false;
            } else {
                search_step[list_id] *= 2;
                search_probe[list_id] = std::min(search_base[list_id] + search_step[list_id] - 1,
                                                 size[list_id] - 1);
            }
            continue;
        }
        auto low = search_low[list_id];
        auto high = probe + 1;
        while (low < high) {
            const auto middle = low + (high - low) / 2;
            if (input[base[list_id] + middle] < candidate) low = middle + 1;
            else high = middle;
        }
        if (low < size[list_id] && input[base[list_id] + low] == candidate) {
            color[list_id] = Color::green;
            cursor[list_id] = low + 1;
        } else {
            color[list_id] = Color::red;
            representative[list_id] = low;
            representative_present[list_id] = low < size[list_id];
        }
    }

    const auto output_bytes = 8 * (1 + result_count);
    if (output == nullptr || capacity < output_bytes) return -2;
    put_i64_le(output, 0, static_cast<std::int64_t>(result_count));
    for (std::size_t i = 0; i < result_count; ++i) put_i64_le(output, 8 * (i + 1), result[i]);
    return static_cast<std::int64_t>(output_bytes);
}
