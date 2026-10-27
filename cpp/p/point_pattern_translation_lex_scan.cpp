#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_PATTERN = 6, MAX_TARGET = 8, MAX_COORD = 16, MAX_INPUT = 31;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
bool point_less(std::int64_t ax, std::int64_t ay, std::int64_t bx, std::int64_t by) {
    return ax < bx || (ax == bx && ay < by);
}
}

extern "C" std::int64_t point_pattern_translation_lex_scan(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > MAX_INPUT) return -1;
    const auto pattern_raw = input[0], target_raw = input[1];
    if (pattern_raw < 1 || pattern_raw > MAX_PATTERN || target_raw < 1 || target_raw > MAX_TARGET || pattern_raw > target_raw) return -1;
    const int pattern_count = static_cast<int>(pattern_raw), target_count = static_cast<int>(target_raw);
    if (length != static_cast<std::size_t>(2 + 2 * (pattern_count + target_count))) return -1;
    std::array<std::int64_t, MAX_PATTERN> px{}, py{};
    std::array<std::int64_t, MAX_TARGET> tx{}, ty{};
    std::size_t cursor = 2;
    for (int i = 0; i < pattern_count; ++i) {
        px[i] = input[cursor++]; py[i] = input[cursor++];
        if (px[i] < -MAX_COORD || px[i] > MAX_COORD || py[i] < -MAX_COORD || py[i] > MAX_COORD) return -1;
        if (i > 0 && !point_less(px[i - 1], py[i - 1], px[i], py[i])) return -1;
    }
    for (int i = 0; i < target_count; ++i) {
        tx[i] = input[cursor++]; ty[i] = input[cursor++];
        if (tx[i] < -MAX_COORD || tx[i] > MAX_COORD || ty[i] < -MAX_COORD || ty[i] > MAX_COORD) return -1;
        if (i > 0 && !point_less(tx[i - 1], ty[i - 1], tx[i], ty[i])) return -1;
    }
    if (output == nullptr || capacity < 24) return -2;

    std::int64_t found = 0, best_x = 0, best_y = 0;
    for (int anchor = 0; anchor < target_count && found == 0; ++anchor) {
        const auto dx = tx[anchor] - px[0], dy = ty[anchor] - py[0];
        int target_index = anchor + 1;
        bool matches = true;
        for (int pattern_index = 1; pattern_index < pattern_count; ++pattern_index) {
            const auto wanted_x = px[pattern_index] + dx, wanted_y = py[pattern_index] + dy;
            while (target_index < target_count && point_less(tx[target_index], ty[target_index], wanted_x, wanted_y)) ++target_index;
            if (target_index >= target_count || tx[target_index] != wanted_x || ty[target_index] != wanted_y) { matches = false; break; }
            ++target_index;
        }
        if (matches) { found = 1; best_x = dx; best_y = dy; }
    }
    std::array<std::uint8_t, 24> staged{};
    store_i64_le(staged.data(), 0, found); store_i64_le(staged.data(), 8, best_x); store_i64_le(staged.data(), 16, best_y);
    for (std::size_t byte = 0; byte < staged.size(); ++byte) output[byte] = staged[byte];
    return 24;
}
