#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 128;
constexpr std::size_t max_input_length = max_nodes + 1;

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t median_search2(const std::int64_t* input, std::size_t length,
                                        std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_nodes)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != count + 1) return -1;
    for (std::size_t i = 0; i < count; ++i)
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;

    std::int32_t next[max_nodes];
    for (std::size_t i = 0; i < count; ++i)
        next[i] = i + 1 < count ? static_cast<std::int32_t>(i + 1) : -1;
    std::int32_t found = 0, median_index = -1;
    if (count > 0) {
        std::int32_t slow = 0, fast = 0;
        while (next[fast] >= 0 && next[next[fast]] >= 0) {
            slow = next[slow];
            fast = next[next[fast]];
        }
        median_index = next[fast] >= 0 ? next[slow] : slow;
        found = 1;
    }
    if (output == nullptr || capacity < 8) return -2;
    std::uint8_t buffer[8];
    put_i32_le(buffer, 0, found);
    put_i32_le(buffer, 4, median_index);
    for (std::size_t i = 0; i < sizeof buffer; ++i) output[i] = buffer[i];
    return 8;
}
