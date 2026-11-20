/* Clean-room bounded lattice diffusion-limited aggregation. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t side_length = 33;
constexpr int max_attempts = 16;
constexpr int max_steps = 512;
constexpr std::uint64_t golden = UINT64_C(0x9e3779b97f4a7c15);
constexpr std::uint64_t multiplier = UINT64_C(0x2545f4914f6cdd1d);

std::uint64_t next_word(std::uint64_t &state) {
    state ^= state >> 12;
    state ^= state << 25;
    state ^= state >> 27;
    return state * multiplier;
}

bool touches(const std::array<std::uint8_t, side_length * side_length> &occupied,
             int x, int y) {
    return occupied[static_cast<std::size_t>(y) * side_length + x - 1] != 0 ||
           occupied[static_cast<std::size_t>(y - 1) * side_length + x] != 0 ||
           occupied[static_cast<std::size_t>(y) * side_length + x + 1] != 0 ||
           occupied[static_cast<std::size_t>(y + 1) * side_length + x] != 0;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
} // namespace

extern "C" std::int64_t brownian_tree_diffusion_limited_aggregation(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length != 3) return -1;
    const std::int64_t attempts_value = input[0];
    const std::int64_t seed_value = input[1];
    const std::int64_t steps_value = input[2];
    if (attempts_value < 0 || attempts_value > max_attempts || seed_value < 1 ||
        steps_value < 1 || steps_value > max_steps) return -1;

    std::array<std::uint8_t, side_length * side_length> occupied{};
    std::array<std::int32_t, 17> point_x{};
    std::array<std::int32_t, 17> point_y{};
    int point_count = 1;
    point_x[0] = 16;
    point_y[0] = 16;
    occupied[16 * side_length + 16] = 1;

    for (int attempt = 0; attempt < attempts_value; ++attempt) {
        std::uint64_t state = static_cast<std::uint64_t>(seed_value) ^
            (golden * static_cast<std::uint64_t>(attempt + 1));
        if (state == 0) state = multiplier;
        const std::uint64_t side_draw = next_word(state);
        const std::uint64_t position_draw = next_word(state);
        const std::uint64_t launch_side = side_draw % 4;
        const int position = 1 + static_cast<int>(position_draw % 31);
        int x = launch_side == 1 ? 31 : launch_side == 3 ? 1 : position;
        int y = launch_side == 0 ? 1 : launch_side == 2 ? 31 : position;

        if (occupied[static_cast<std::size_t>(y) * side_length + x] != 0) continue;
        if (touches(occupied, x, y)) {
            occupied[static_cast<std::size_t>(y) * side_length + x] = 1;
            point_x[point_count] = x;
            point_y[point_count++] = y;
            continue;
        }
        for (int step = 0; step < steps_value; ++step) {
            const int direction = static_cast<int>(next_word(state) % 4);
            if (direction == 0) --x;
            else if (direction == 1) --y;
            else if (direction == 2) ++x;
            else ++y;
            if (x == 0 || x == 32 || y == 0 || y == 32) break;
            if (touches(occupied, x, y)) {
                occupied[static_cast<std::size_t>(y) * side_length + x] = 1;
                point_x[point_count] = x;
                point_y[point_count++] = y;
                break;
            }
        }
    }

    const std::size_t required = static_cast<std::size_t>(1 + 2 * point_count) * 8;
    if (output == nullptr || capacity < required) return -2;
    store_i64_le(output, 0, point_count);
    for (int point = 0; point < point_count; ++point) {
        store_i64_le(output, static_cast<std::size_t>(1 + 2 * point) * 8, point_x[point]);
        store_i64_le(output, static_cast<std::size_t>(2 + 2 * point) * 8, point_y[point]);
    }
    return static_cast<std::int64_t>(required);
}
