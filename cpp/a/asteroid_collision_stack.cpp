#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 64;
constexpr std::size_t kMaxInput = 66;
}

extern "C" std::int64_t asteroid_collision_stack(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > kMaxInput) return -1;
    const std::int64_t n_word = input[0];
    if (n_word < 0 || n_word > static_cast<std::int64_t>(kMaxN) ||
        length != static_cast<std::size_t>(n_word) + 1) return -1;

    std::int8_t stack[kMaxN]{};
    std::size_t top = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n_word); ++i) {
        const std::int64_t word = input[i + 1];
        if (word == 0 || word < -127 || word > 127) return -1;
        const std::int8_t incoming = static_cast<std::int8_t>(word);
        bool alive = true;
        while (alive && top > 0 && stack[top - 1] > 0 && incoming < 0) {
            const int left_size = stack[top - 1];
            const int right_size = -static_cast<int>(incoming);
            if (left_size < right_size) --top;
            else if (left_size == right_size) { --top; alive = false; }
            else alive = false;
        }
        if (alive) stack[top++] = incoming;
    }

    const std::size_t required = top + 1;
    if (output == nullptr || capacity < required) return -2;
    output[0] = static_cast<std::uint8_t>(top);
    for (std::size_t i = 0; i < top; ++i)
        output[i + 1] = static_cast<std::uint8_t>(stack[i]);
    return static_cast<std::int64_t>(required);
}
