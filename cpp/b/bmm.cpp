#include <array>
#include <cstddef>
#include <cstdint>

/* Modified bounded-profile derivative; carry benchmarks/b/bmm/LICENSE with this source. */

namespace {
constexpr std::size_t max_size = 128;
constexpr std::size_t source_size = 1024;
constexpr std::size_t max_cells = max_size * max_size;
constexpr std::size_t max_output_bytes = 29;

std::uint32_t next_random(std::uint32_t &state) noexcept {
    state = state * 1664525U + 1013904223U;
    return (state >> 16) & 0x7fffU;
}

std::size_t append_unsigned(std::uint32_t value, std::array<std::uint8_t, max_output_bytes> &staged,
                            std::size_t used) noexcept {
    std::uint8_t reverse[10];
    std::size_t count = 0;
    do {
        reverse[count++] = static_cast<std::uint8_t>('0' + value % 10U);
        value /= 10U;
    } while (value != 0U);
    while (count != 0U) staged[used++] = reverse[--count];
    return used;
}
}

extern "C" std::int64_t versabench_bmm(const std::int64_t *input, std::size_t length,
                                        std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length != 2) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_size) ||
        input[1] < 1 || input[1] > input[0] || input[0] % input[1] != 0) return -1;

    const auto size = static_cast<std::size_t>(input[0]);
    const auto block = static_cast<std::size_t>(input[1]);
    std::array<float, max_cells> a{};
    std::array<float, max_cells> b{};
    std::array<float, max_cells> c{};
    std::uint32_t seed = 1U;

    for (std::size_t i = 0; i < size; ++i) {
        for (std::size_t j = 0; j < source_size; ++j) {
            const auto random_a = next_random(seed);
            const auto random_b = next_random(seed);
            if (j < size) {
                const auto shift_a = (static_cast<std::uint32_t>(j & 31U) + 32U -
                                      static_cast<std::uint32_t>(i & 31U)) & 31U;
                const auto shift_b = (static_cast<std::uint32_t>(i) +
                                      static_cast<std::uint32_t>(j)) & 31U;
                a[i * size + j] = static_cast<float>((random_a >> shift_a) & 15U);
                b[i * size + j] = static_cast<float>((random_b << shift_b) & 15U);
            }
        }
    }

    for (std::size_t outer_i = 0; outer_i < size; outer_i += block)
        for (std::size_t outer_j = 0; outer_j < size; outer_j += block)
            for (std::size_t outer_k = 0; outer_k < size; outer_k += block)
                for (std::size_t i = outer_i; i < outer_i + block; ++i)
                    for (std::size_t j = outer_j; j < outer_j + block; ++j) {
                        const auto cell = i * size + j;
                        for (std::size_t k = outer_k; k < outer_k + block; ++k)
                            c[cell] += a[i * size + k] * b[k * size + j];
                    }

    float total = 0.0F;
    for (std::size_t outer_i = 0; outer_i < size; outer_i += block)
        for (std::size_t outer_j = 0; outer_j < size; outer_j += block) {
            float subtotal = 0.0F;
            for (std::size_t i = outer_i; i < outer_i + block; ++i)
                for (std::size_t j = outer_j; j < outer_j + block; ++j)
                    subtotal += c[i * size + j];
            total += subtotal;
        }

    std::array<std::uint8_t, max_output_bytes> staged{};
    std::size_t used = 0;
    constexpr char prefix[] = "final sum = ";
    for (std::size_t i = 0; i < sizeof(prefix) - 1; ++i) staged[used++] = static_cast<std::uint8_t>(prefix[i]);
    used = append_unsigned(static_cast<std::uint32_t>(total), staged, used);
    constexpr char suffix[] = ".000000\n";
    for (std::size_t i = 0; i < sizeof(suffix) - 1; ++i) staged[used++] = static_cast<std::uint8_t>(suffix[i]);
    if (output == nullptr || output_capacity < used) return -2;
    for (std::size_t i = 0; i < used; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(used);
}
