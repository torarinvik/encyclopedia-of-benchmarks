#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t input_count = 40;
constexpr std::size_t max_input_length = 41;
constexpr std::size_t output_bytes = 112;

std::int64_t asr2(std::int64_t value) noexcept
{
    return value >= 0 ? value / 4 : -(((-value) + 3) / 4);
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t mediabench_gsm_rpe_grid_selection(
    const std::int64_t* input, std::size_t input_length,
    std::uint8_t* output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length == 0 || input_length > max_input_length) return -1;
    for (std::size_t i = 0; i < input_length; ++i)
        if (input[i] < -32768 || input[i] > 32767) return -1;
    if (input_length != input_count) return -1;

    std::int64_t best_score = -1, best_grid = 0;
    for (std::int64_t grid = 0; grid < 4; ++grid) {
        std::int64_t sum = 0;
        for (std::int64_t i = 0; i < 13; ++i) {
            const std::int64_t scaled = asr2(input[grid + 3 * i]);
            sum += scaled * scaled;
        }
        const std::int64_t score = 2 * sum;
        if (score > best_score) { best_score = score; best_grid = grid; }
    }
    std::int64_t staged[14];
    staged[0] = best_grid;
    for (std::int64_t i = 0; i < 13; ++i) staged[1 + i] = input[best_grid + 3 * i];
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < 14; ++i) store_i64_le(output, 8 * i, staged[i]);
    return static_cast<std::int64_t>(output_bytes);
}
