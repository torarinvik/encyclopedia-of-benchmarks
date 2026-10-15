#include <cstddef>
#include <cstdint>

namespace {
void generate(int pairs, int opened, int closed, std::uint8_t *buffer,
              std::uint8_t *output, std::size_t &cursor)
{
    const int position = opened + closed;
    if (position == 2 * pairs) {
        for (int index = 0; index < position; ++index) output[cursor++] = buffer[index];
        return;
    }
    if (opened < pairs) {
        buffer[position] = '(';
        generate(pairs, opened + 1, closed, buffer, output, cursor);
    }
    if (closed < opened) {
        buffer[position] = ')';
        generate(pairs, opened, closed + 1, buffer, output, cursor);
    }
}
}

extern "C" std::int64_t generate_parentheses(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) noexcept
{
    static constexpr std::size_t required_bytes[] = {0, 2, 8, 30, 112, 420, 1584};
    if (input == nullptr || length != 1 || input[0] < 1 || input[0] > 6) return -1;
    const int pairs = static_cast<int>(input[0]);
    const std::size_t required = required_bytes[pairs];
    if (capacity < required || output == nullptr) return -2;
    std::uint8_t buffer[12];
    std::size_t cursor = 0;
    generate(pairs, 0, 0, buffer, output, cursor);
    return static_cast<std::int64_t>(cursor);
}
