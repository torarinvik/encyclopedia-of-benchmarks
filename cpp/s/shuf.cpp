#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 67;

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value)
{
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t shuf(const std::int64_t *input, std::size_t length,
                              std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto count_raw = input[0], sample_size_raw = input[1];
    if (count_raw < 0 || count_raw > 32 || sample_size_raw < 1 || sample_size_raw > 32) return -1;
    const auto count = static_cast<std::size_t>(count_raw);
    const auto sample_size = static_cast<std::size_t>(sample_size_raw);
    if (length != 2 + 2 * count) return -1;

    std::int32_t items[32], sample[32];
    bool occupied[32]{};
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[2 + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        items[index] = static_cast<std::int32_t>(value);
    }
    const auto initial_count = count < sample_size ? count : sample_size;
    for (std::size_t index = 0; index < initial_count; ++index) {
        const auto draw = input[2 + count + index];
        if (draw < 0 || static_cast<std::uint64_t>(draw) >= sample_size) return -1;
        auto slot = static_cast<std::size_t>(draw);
        while (occupied[slot]) slot = (slot + 1) % sample_size;
        sample[slot] = items[index];
        occupied[slot] = true;
    }
    if (count >= sample_size) {
        for (std::size_t index = sample_size; index < count; ++index) {
            const auto draw = input[2 + count + index];
            if (draw < 0 || static_cast<std::uint64_t>(draw) > index) return -1;
            if (static_cast<std::size_t>(draw) < sample_size) sample[static_cast<std::size_t>(draw)] = items[index];
        }
    }

    const auto result_count = initial_count;
    const auto output_bytes = result_count * 4;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    std::size_t out_index = 0;
    for (std::size_t slot = 0; slot < sample_size; ++slot)
        if (occupied[slot]) write_i32_le(output, out_index++ * 4, sample[slot]);
    return static_cast<std::int64_t>(out_index);
}
