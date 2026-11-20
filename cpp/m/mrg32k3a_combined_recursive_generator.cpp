#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t m1 = INT64_C(4294967087);
constexpr std::int64_t m2 = INT64_C(4294944443);
constexpr std::int64_t max_count = 64;

std::int64_t residue(std::int64_t value, std::int64_t modulus) {
    const auto result = value % modulus;
    return result < 0 ? result + modulus : result;
}

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t mrg32k3a_combined_recursive_generator(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length != 7) return -1;
    for (std::size_t i = 0; i < 3; ++i)
        if (input[i] < 0 || input[i] >= m1) return -1;
    for (std::size_t i = 3; i < 6; ++i)
        if (input[i] < 0 || input[i] >= m2) return -1;
    if ((input[0] | input[1] | input[2]) == 0 ||
        (input[3] | input[4] | input[5]) == 0 ||
        input[6] < 0 || input[6] > max_count) return -1;

    const auto count = static_cast<std::size_t>(input[6]);
    const auto required = count * 8;
    if (capacity < required || (required != 0 && output == nullptr)) return -2;
    if (count == 0) return 0;

    std::int64_t x1[3] = {input[0], input[1], input[2]};
    std::int64_t x2[3] = {input[3], input[4], input[5]};
    for (std::size_t step = 0; step < count; ++step) {
        const auto next1 = residue(INT64_C(1403580) * x1[1] -
                                   INT64_C(810728) * x1[0], m1);
        const auto next2 = residue(INT64_C(527612) * x2[2] -
                                   INT64_C(1370589) * x2[0], m2);
        x1[0] = x1[1]; x1[1] = x1[2]; x1[2] = next1;
        x2[0] = x2[1]; x2[1] = x2[2]; x2[2] = next2;
        auto z = next1 - next2;
        if (z < 0) z += m1;
        put_i64_le(output, step * 8, z);
    }
    return static_cast<std::int64_t>(required);
}
