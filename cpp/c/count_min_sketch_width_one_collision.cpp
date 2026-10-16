#include <cstddef>
#include <cstdint>

namespace {
void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t count_min_sketch_width_one_collision(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > 513) return -1;
    const auto count_value = input[0];
    if (count_value < 0 || count_value > 256 || length != 1 + static_cast<std::size_t>(count_value) * 2) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    std::size_t queries = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto operation = input[1 + 2 * i];
        const auto key = input[2 + 2 * i];
        if ((operation != 0 && operation != 1) || key < -1000000 || key > 1000000) return -1;
        if (operation == 1) ++queries;
    }
    const std::size_t required = queries * 8;
    if (capacity < required || (required > 0 && output == nullptr)) return -2;
    std::int64_t inserts = 0;
    std::size_t output_offset = 0;
    for (std::size_t i = 0; i < count; ++i) {
        if (input[1 + 2 * i] == 0) ++inserts;
        else { put_i64_le(output, output_offset, inserts); output_offset += 8; }
    }
    return static_cast<std::int64_t>(required);
}
