#include <cstddef>
#include <cstdint>

static void put32(std::uint8_t *out, std::uint32_t x) {
    for (std::size_t i = 0; i < 4; ++i) out[i] = static_cast<std::uint8_t>(x >> (8 * i));
}
static void put_f64(std::uint8_t *out, double x) {
    union Bits { double f; std::uint64_t u; } bits{x};
    for (std::size_t i = 0; i < 8; ++i) out[4 + i] = static_cast<std::uint8_t>(bits.u >> (8 * i));
}
extern "C" std::int64_t evaluate_expression(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 3 || length > 131) return -1;
    const std::int64_t count = input[0];
    if (count < 1 || count > 64 || length != static_cast<std::size_t>(1 + 2 * count)) return -1;
    double stack[64]{};
    std::size_t depth = 0;
    bool valid = true;
    for (std::int64_t i = 0; i < count; ++i) {
        const auto op = input[1 + 2 * i], payload = input[2 + 2 * i];
        if (op == 0) {
            if (payload < -1000000000 || payload > 1000000000) return -1;
            stack[depth++] = static_cast<double>(payload) / 1000.0;
        } else if (op >= 1 && op <= 4) {
            if (payload != 0) return -1;
            if (depth < 2) { valid = false; break; }
            const double right = stack[--depth], left = stack[--depth];
            if (op == 1) stack[depth++] = left + right;
            else if (op == 2) stack[depth++] = left - right;
            else if (op == 3) stack[depth++] = left * right;
            else if (right == 0.0) { valid = false; break; }
            else stack[depth++] = left / right;
        } else { valid = false; break; }
    }
    valid = valid && depth == 1;
    const std::size_t needed = valid ? 12 : 4;
    if (!output || capacity < needed) return -2;
    put32(output, valid ? 1u : 0u);
    if (valid) put_f64(output, stack[0]);
    return static_cast<std::int64_t>(needed);
}
