/* Generate the nth count-and-say term as ASCII bytes. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_term_length = 256; }

extern "C" std::int64_t count_and_say(std::int64_t term_index, std::uint8_t *output,
        std::size_t output_capacity) noexcept {
    if (term_index < 1 || term_index > 19) return -1;
    std::array<std::uint8_t, max_term_length> current{};
    std::array<std::uint8_t, max_term_length> next{};
    std::size_t current_length = 1;
    current[0] = '1';
    for (std::int64_t term = 1; term < term_index; ++term) {
        std::size_t next_length = 0;
        for (std::size_t index = 0; index < current_length;) {
            std::size_t end = index + 1;
            while (end < current_length && current[end] == current[index]) ++end;
            const auto run_length = end - index;
            if (next_length + 2 > max_term_length) return -1;
            next[next_length++] = static_cast<std::uint8_t>('0' + run_length);
            next[next_length++] = current[index];
            index = end;
        }
        for (std::size_t index = 0; index < next_length; ++index) current[index] = next[index];
        current_length = next_length;
    }
    if (output_capacity < current_length || output == nullptr) return -2;
    for (std::size_t index = 0; index < current_length; ++index) output[index] = current[index];
    return static_cast<std::int64_t>(current_length);
}
