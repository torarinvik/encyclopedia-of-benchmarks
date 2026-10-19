#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 10;
constexpr std::size_t max_output_bytes = 89;

std::int64_t ackermann_value(std::int64_t x, std::int64_t y) {
    if (x == 0) return y + 1;
    return ackermann_value(x - 1, y == 0 ? 1 : ackermann_value(x, y - 1));
}

std::int64_t fibonacci_integer(std::int64_t n) {
    if (n < 2) return 1;
    return fibonacci_integer(n - 2) + fibonacci_integer(n - 1);
}

double fibonacci_float(double n) {
    if (n < 2.0) return 1.0;
    return fibonacci_float(n - 2.0) + fibonacci_float(n - 1.0);
}

std::int64_t takeuchi_integer(std::int64_t x, std::int64_t y, std::int64_t z) {
    if (y < x)
        return takeuchi_integer(takeuchi_integer(x - 1, y, z),
                                takeuchi_integer(y - 1, z, x),
                                takeuchi_integer(z - 1, x, y));
    return z;
}

double takeuchi_float(double x, double y, double z) {
    if (y < x)
        return takeuchi_float(takeuchi_float(x - 1.0, y, z),
                              takeuchi_float(y - 1.0, z, x),
                              takeuchi_float(z - 1.0, x, y));
    return z;
}

void append_text(std::uint8_t *buffer, std::size_t &used, const char *text) {
    while (*text != '\0') buffer[used++] = static_cast<std::uint8_t>(*text++);
}

void append_number(std::uint8_t *buffer, std::size_t &used, std::int64_t value) {
    std::uint8_t reversed[20];
    std::size_t count = 0;
    do {
        reversed[count++] = static_cast<std::uint8_t>('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) buffer[used++] = reversed[--count];
}
}

extern "C" std::int64_t benchmarkgame_recursive(std::int64_t n,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (n < 0 || n > max_n) return -1;
    if (output == nullptr) return -2;

    std::uint8_t staged[max_output_bytes];
    std::size_t used = 0;
    append_text(staged, used, "Ack(3,");
    append_number(staged, used, n + 1);
    append_text(staged, used, "): ");
    append_number(staged, used, ackermann_value(3, n + 1));
    append_text(staged, used, "\nFib(");
    append_number(staged, used, 28 + n);
    append_text(staged, used, ".0): ");
    append_number(staged, used, static_cast<std::int64_t>(fibonacci_float(static_cast<double>(28 + n))));
    append_text(staged, used, ".0\nTak(");
    append_number(staged, used, 3 * n);
    append_text(staged, used, ",");
    append_number(staged, used, 2 * n);
    append_text(staged, used, ",");
    append_number(staged, used, n);
    append_text(staged, used, "): ");
    append_number(staged, used, takeuchi_integer(3 * n, 2 * n, n));
    append_text(staged, used, "\nFib(3): ");
    append_number(staged, used, fibonacci_integer(3));
    append_text(staged, used, "\nTak(3.0,2.0,1.0): ");
    append_number(staged, used, static_cast<std::int64_t>(takeuchi_float(3.0, 2.0, 1.0)));
    append_text(staged, used, ".0\n");

    if (output_capacity < used) return -2;
    for (std::size_t index = 0; index < used; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(used);
}
