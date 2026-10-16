// Preserve the six integer weight-conversion strings from the pinned Ruby source.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_amount = 1'000'000;

std::size_t append_text(std::uint8_t *buffer, std::size_t position, const char *text) noexcept {
    while (*text != '\0') buffer[position++] = static_cast<std::uint8_t>(*text++);
    return position;
}

std::size_t append_i64(std::uint8_t *buffer, std::size_t position, std::int64_t value) noexcept {
    std::uint8_t digits[24];
    std::size_t count = 0;
    std::uint64_t magnitude;
    if (value < 0) {
        buffer[position++] = '-';
        magnitude = static_cast<std::uint64_t>(-(value + 1)) + 1;
    } else {
        magnitude = static_cast<std::uint64_t>(value);
    }
    do {
        digits[count++] = static_cast<std::uint8_t>('0' + magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    while (count != 0) buffer[position++] = digits[--count];
    return position;
}

std::size_t append_fixed(std::uint8_t *buffer, std::size_t position, double value) noexcept {
    const double scaled = value * 100.0;
    std::int64_t cents = value < 0.0
        ? -static_cast<std::int64_t>(-scaled + 0.5)
        : static_cast<std::int64_t>(scaled + 0.5);
    if (value > 0.0 && (static_cast<double>(cents) + 0.5) / 100.0 <= value) ++cents;
    else if (value < 0.0 && (static_cast<double>(cents) - 0.5) / 100.0 >= value) --cents;
    if (cents < 0) {
        buffer[position++] = '-';
        cents = -cents;
    }
    position = append_i64(buffer, position, cents / 100);
    const std::int64_t fraction = cents % 100;
    buffer[position++] = '.';
    if (fraction == 0) buffer[position++] = '0';
    else if (fraction % 10 == 0) buffer[position++] = static_cast<std::uint8_t>('0' + fraction / 10);
    else {
        buffer[position++] = static_cast<std::uint8_t>('0' + fraction / 10);
        buffer[position++] = static_cast<std::uint8_t>('0' + fraction % 10);
    }
    return position;
}
}

extern "C" std::int64_t weight_conversions(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t output_capacity) noexcept {
    if (input == nullptr || length != 2 || input[0] < 0 || input[0] > 5 ||
        input[1] < -max_amount || input[1] > max_amount) return -1;

    const std::int64_t operation = input[0];
    const std::int64_t amount = input[1];
    std::uint8_t buffer[64];
    std::size_t position = 0;
    std::int64_t converted = 0;
    if (operation == 0) {
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " kg = ");
        position = append_i64(buffer, position, amount * 1000);
        position = append_text(buffer, position, " g");
    } else if (operation == 1) {
        converted = amount >= 0 ? amount / 1000 : -((-amount + 999) / 1000);
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " g = ");
        position = append_i64(buffer, position, converted);
        position = append_text(buffer, position, " kg");
    } else if (operation == 2) {
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " lb = ");
        position = append_i64(buffer, position, amount * 16);
        position = append_text(buffer, position, " oz");
    } else if (operation == 3) {
        converted = amount >= 0 ? amount / 16 : -((-amount + 15) / 16);
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " oz = ");
        position = append_i64(buffer, position, converted);
        position = append_text(buffer, position, " lb");
    } else if (operation == 4) {
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " kg = ");
        position = append_fixed(buffer, position, static_cast<double>(amount) * 2.205);
        position = append_text(buffer, position, " lb");
    } else {
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " lb = ");
        position = append_fixed(buffer, position, static_cast<double>(amount) / 2.205);
        position = append_text(buffer, position, " kg");
    }

    buffer[position] = 0;
    if (output_capacity < position + 1 || output == nullptr) return -2;
    for (std::size_t index = 0; index <= position; ++index) output[index] = buffer[index];
    return static_cast<std::int64_t>(position);
}
