#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t digital_filter_direct_form_ii_transposed(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    constexpr std::size_t max_samples = 32;
    constexpr std::size_t max_order = 4;
    constexpr std::size_t max_input_words = 45;
    if (input == nullptr || length < 2 || length > max_input_words) return -1;
    const auto count_word = input[0];
    const auto order_word = input[1];
    if (count_word < 0 || count_word > static_cast<std::int64_t>(max_samples) ||
        order_word < 0 || order_word > static_cast<std::int64_t>(max_order)) return -1;
    const auto count = static_cast<std::size_t>(count_word);
    const auto order = static_cast<std::size_t>(order_word);
    if (length != count + 2 * order + 4) return -1;

    const std::size_t a_start = 2;
    const std::size_t b_start = order + 3;
    const std::size_t x_start = 2 * order + 4;
    if (input[a_start] != 1) return -1;
    for (std::size_t i = 1; i <= order; ++i)
        if (input[a_start + i] < -1 || input[a_start + i] > 1) return -1;
    for (std::size_t i = 0; i <= order; ++i)
        if (input[b_start + i] < -1 || input[b_start + i] > 1) return -1;
    for (std::size_t i = 0; i < count; ++i)
        if (input[x_start + i] < -16 || input[x_start + i] > 16) return -1;

    const auto bytes = count * 8;
    if (bytes != 0 && (output == nullptr || capacity < bytes)) return -2;
    if (count == 0) return 0;

    std::array<std::int64_t, max_order> state{};
    for (std::size_t index = 0; index < count; ++index) {
        const auto sample = input[x_start + index];
        const auto value = input[b_start] * sample + (order == 0 ? 0 : state[0]);
        for (std::size_t stage = 0; stage < order; ++stage) {
            const auto next_state = stage + 1 < order ? state[stage + 1] : 0;
            state[stage] = next_state + input[b_start + stage + 1] * sample
                         - input[a_start + stage + 1] * value;
        }
        const auto bits = static_cast<std::uint64_t>(value);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(bytes);
}
