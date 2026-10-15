#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 64;
constexpr std::size_t BYTES_PER_TRIPLET = 12;

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < 4; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

std::size_t enumerate(const std::int64_t *values, std::size_t length, std::uint8_t *output, bool write_output)
{
    std::size_t count = 0;
    bool has_last = false;
    std::int64_t last_a = 0, last_b = 0, last_c = 0;
    for (std::size_t i = 0; i + 2 < length; ++i) {
        for (std::size_t j = i + 1; j + 1 < length; ++j) {
            for (std::size_t k = j + 1; k < length; ++k) {
                if (values[i] + values[j] + values[k] != 0) continue;
                if (has_last && values[i] == last_a && values[j] == last_b && values[k] == last_c) continue;
                if (write_output) {
                    const auto offset = count * BYTES_PER_TRIPLET;
                    write_i32_le(output, offset, values[i]);
                    write_i32_le(output, offset + 4, values[j]);
                    write_i32_le(output, offset + 8, values[k]);
                }
                last_a = values[i]; last_b = values[j]; last_c = values[k]; has_last = true;
                ++count;
            }
        }
    }
    return count;
}
}

extern "C" std::int64_t find_triplets_with_0_sum(const std::int64_t *input, std::size_t length,
                                                   std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length > MAX_ITEMS || (length > 0 && input == nullptr)) return -1;
    std::int64_t values[MAX_ITEMS];
    for (std::size_t i = 0; i < length; ++i) {
        if (input[i] < -100000 || input[i] > 100000) return -1;
        values[i] = input[i];
    }
    for (std::size_t i = 1; i < length; ++i) {
        const auto key = values[i];
        std::size_t j = i;
        while (j > 0 && values[j - 1] > key) { values[j] = values[j - 1]; --j; }
        values[j] = key;
    }
    const auto count = enumerate(values, length, nullptr, false);
    if (count == 0) return 0;
    const auto needed = count * BYTES_PER_TRIPLET;
    if (output == nullptr || output_capacity < needed) return -2;
    return static_cast<std::int64_t>(enumerate(values, length, output, true));
}
