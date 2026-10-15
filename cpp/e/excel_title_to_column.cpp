#include <cstddef>
#include <cstdint>

extern "C" std::int64_t excel_title_to_column(const std::int64_t *values,
                                               std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 13) return -1;
    const auto count = values[0];
    if (count < 1 || count > 12 || length != static_cast<std::size_t>(1 + count)) return -1;

    std::int64_t column = 0;
    for (std::int64_t index = 0; index < count; ++index) {
        auto letter = values[1 + index];
        if (letter >= 97 && letter <= 122) letter -= 32;
        if (letter < 65 || letter > 90) return -1;
        column = column * 26 + (letter - 65 + 1);
    }
    return column;
}
