/* Minimum updates needed to equalize a vector with a fixed step size. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t matrix_equalization(const std::int64_t *input,
                                             std::size_t length) noexcept
{
    constexpr std::size_t max_vector_length = 64;
    constexpr std::size_t max_input_length = max_vector_length + 2;
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto vector_length = length - 1;
    if (vector_length > max_vector_length || input[0] < 1 ||
        input[0] > static_cast<std::int64_t>(vector_length)) return -1;
    const auto step_size = static_cast<std::size_t>(input[0]);
    auto minimum_updates = vector_length;

    for (std::size_t target_index = 0; target_index < vector_length; ++target_index) {
        bool seen = false;
        for (std::size_t previous = 0; previous < target_index; ++previous) {
            if (input[previous + 1] == input[target_index + 1]) {
                seen = true;
                break;
            }
        }
        if (seen) continue;

        std::size_t updates = 0;
        std::size_t index = 0;
        while (index < vector_length) {
            if (input[index + 1] == input[target_index + 1]) {
                ++index;
            } else {
                ++updates;
                index += step_size;
            }
        }
        if (updates < minimum_updates) minimum_updates = updates;
    }
    return static_cast<std::int64_t>(minimum_updates);
}
