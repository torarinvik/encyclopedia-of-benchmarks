#include <cstddef>
#include <cstdint>

static std::int64_t get_check_digit(std::int64_t barcode)
{
    barcode /= 10;
    bool checker = false;
    std::int64_t sum = 0;
    while (barcode != 0) {
        sum += (checker ? 1 : 3) * (barcode % 10);
        barcode /= 10;
        checker = !checker;
    }
    return (10 - sum % 10) % 10;
}

static std::size_t decimal_length(std::int64_t value)
{
    std::size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

extern "C" std::int64_t barcode_validator(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 2 || values[0] < 0 || values[0] > 1 || values[1] < 0)
        return -1;
    const auto barcode = values[1];
    if (values[0] == 0) return get_check_digit(barcode);
    return decimal_length(barcode) == 13 && get_check_digit(barcode) == barcode % 10;
}
