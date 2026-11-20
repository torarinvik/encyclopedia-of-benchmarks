#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxOrder = 2;
constexpr std::size_t kMaxParseableInput = 2;
constexpr std::size_t kMaxStack = 64;
struct Frame { std::uint8_t symbol; std::uint8_t level; };

void push(Frame (&stack)[kMaxStack], std::size_t &top,
          std::uint8_t symbol, std::uint8_t level) {
    stack[top++] = Frame{symbol, level};
}

std::size_t emit_curve(std::uint8_t order, std::uint8_t *output) {
    Frame stack[kMaxStack]{};
    std::size_t top = 0;
    std::size_t written = 0;
    push(stack, top, 5, 0); push(stack, top, 3, order);
    push(stack, top, 7, 0); push(stack, top, 2, order);
    push(stack, top, 9, 0); push(stack, top, 1, order);
    push(stack, top, 11, 0); push(stack, top, 0, order);
    while (top != 0) {
        const Frame frame = stack[--top];
        if (frame.symbol >= 4) { output[written++] = frame.symbol - 4; continue; }
        if (frame.level == 0) continue;
        const auto child = static_cast<std::uint8_t>(frame.level - 1);
        switch (frame.symbol) {
            case 0:
                push(stack, top, 0, child); push(stack, top, 5, 0);
                push(stack, top, 3, child); push(stack, top, 12, 0);
                push(stack, top, 1, child); push(stack, top, 11, 0);
                push(stack, top, 0, child); break;
            case 1:
                push(stack, top, 1, child); push(stack, top, 11, 0);
                push(stack, top, 0, child); push(stack, top, 18, 0);
                push(stack, top, 2, child); push(stack, top, 9, 0);
                push(stack, top, 1, child); break;
            case 2:
                push(stack, top, 2, child); push(stack, top, 9, 0);
                push(stack, top, 1, child); push(stack, top, 16, 0);
                push(stack, top, 3, child); push(stack, top, 7, 0);
                push(stack, top, 2, child); break;
            default:
                push(stack, top, 3, child); push(stack, top, 7, 0);
                push(stack, top, 2, child); push(stack, top, 14, 0);
                push(stack, top, 0, child); push(stack, top, 5, 0);
                push(stack, top, 3, child); break;
        }
    }
    return written;
}
}

extern "C" std::int64_t sierpinski_curve_trace(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length == 0 || length > kMaxParseableInput) return -1;
    if (length != 1 || input[0] < 0 || input[0] > static_cast<std::int64_t>(kMaxOrder)) return -1;
    const auto order = static_cast<std::size_t>(input[0]);
    std::size_t required = 4;
    for (std::size_t i = 0; i < order; ++i) required *= 4;
    if (output == nullptr || capacity < required) return -2;
    return static_cast<std::int64_t>(emit_curve(static_cast<std::uint8_t>(order), output));
}
