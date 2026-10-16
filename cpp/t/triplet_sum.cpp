#include <cstddef>
#include <cstdint>

namespace {
void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
void sort_three(std::int64_t &first, std::int64_t &second, std::int64_t &third) {
    if (first > second) { const auto value = first; first = second; second = value; }
    if (second > third) { const auto value = second; second = third; third = value; }
    if (first > second) { const auto value = first; first = second; second = value; }
}
}

extern "C" std::int64_t triplet_sum(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity) {
    constexpr std::size_t max_items = 10;
    if (input == nullptr || length < 1 || length > max_items + 1 ||
        input[0] < -3000000 || input[0] > 3000000) return -1;
    const std::size_t item_count = length - 1;
    for (std::size_t index = 0; index < item_count; ++index)
        if (input[index + 1] < -1000000 || input[index + 1] > 1000000) return -1;
    if (output_capacity < 24 || output == nullptr) return -2;

    std::int64_t result[3] = {0, 0, 0};
    bool found = false;
    for (std::size_t first = 0; first < item_count && !found; ++first) {
        for (std::size_t second = 0; second < item_count && !found; ++second) {
            if (second == first) continue;
            for (std::size_t third = 0; third < item_count; ++third) {
                if (third == first || third == second) continue;
                if (input[first + 1] + input[second + 1] + input[third + 1] == input[0]) {
                    result[0] = input[first + 1]; result[1] = input[second + 1]; result[2] = input[third + 1];
                    sort_three(result[0], result[1], result[2]);
                    found = true;
                    break;
                }
            }
        }
    }
    for (std::size_t index = 0; index < 3; ++index) put_i64_le(output, index * 8, result[index]);
    return 3;
}
