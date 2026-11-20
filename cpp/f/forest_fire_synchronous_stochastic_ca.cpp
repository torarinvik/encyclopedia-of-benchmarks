#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cells = 64;
constexpr std::size_t max_input = 1095;

void put_i64(std::uint8_t* out, std::size_t word, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        out[word * 8 + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t forest_fire_synchronous_stochastic_ca(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 6 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > 8 ||
        input[2] < 0 || input[2] > 8 || input[3] != 10000 ||
        input[4] < 0 || input[4] > 10000 || input[5] < 0 || input[5] > 10000) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto cols = static_cast<std::size_t>(input[1]);
    const auto steps = static_cast<std::size_t>(input[2]);
    const auto cells = rows * cols;
    if (length != 6 + cells + 2 * steps * cells) return -1;
    for (std::size_t i = 0; i < cells; ++i) if (input[6 + i] < 0 || input[6 + i] > 2) return -1;
    for (std::size_t r = 0; r < rows; ++r) for (std::size_t c = 0; c < cols; ++c)
        if ((r == 0 || r + 1 == rows || c == 0 || c + 1 == cols) && input[6 + r * cols + c] != 0) return -1;
    const std::size_t tape = 6 + cells;
    for (std::size_t i = 0; i < 2 * steps * cells; ++i)
        if (input[tape + i] < 0 || input[tape + i] >= 10000) return -1;
    const auto bytes = (1 + 3 * steps + cells) * 8;
    if (output == nullptr || capacity < bytes) return -2;

    std::array<std::uint8_t, max_cells> current{};
    std::array<std::uint8_t, max_cells> next{};
    for (std::size_t i = 0; i < cells; ++i) current[i] = static_cast<std::uint8_t>(input[6 + i]);
    put_i64(output, 0, static_cast<std::int64_t>(steps));
    for (std::size_t tick = 0; tick < steps; ++tick) {
        for (std::size_t r = 0; r < rows; ++r) for (std::size_t c = 0; c < cols; ++c) {
            const auto site = r * cols + c;
            if (r == 0 || r + 1 == rows || c == 0 || c + 1 == cols) { next[site] = 0; continue; }
            if (current[site] == 2) { next[site] = 0; continue; }
            if (current[site] == 0) {
                next[site] = input[tape + tick * cells + site] < input[4] ? 1 : 0;
                continue;
            }
            bool near_fire = false;
            for (std::size_t rr = r == 0 ? 0 : r - 1; rr <= (r + 1 < rows ? r + 1 : r); ++rr)
                for (std::size_t cc = c == 0 ? 0 : c - 1; cc <= (c + 1 < cols ? c + 1 : c); ++cc)
                    if ((rr != r || cc != c) && current[rr * cols + cc] == 2) near_fire = true;
            const auto strike = input[tape + steps * cells + tick * cells + site];
            next[site] = near_fire || strike < input[5] ? 2 : 1;
        }
        std::array<std::int64_t, 3> totals{};
        for (std::size_t i = 0; i < cells; ++i) ++totals[next[i]];
        const auto base = 1 + 3 * tick;
        for (std::size_t state = 0; state < 3; ++state) put_i64(output, base + state, totals[state]);
        current = next;
    }
    const auto final_base = 1 + 3 * steps;
    for (std::size_t i = 0; i < cells; ++i) put_i64(output, final_base + i, current[i]);
    return static_cast<std::int64_t>(bytes);
}
