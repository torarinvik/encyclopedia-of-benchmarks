#include <cstddef>
#include <cstdint>

namespace {
bool is_leap_year(std::int64_t year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

void decode_offset(std::int64_t offset, std::int64_t &year_out, std::int64_t &ordinal_out) {
    const std::int64_t shifted = offset + 719468;
    const std::int64_t era = shifted / 146097;
    const std::int64_t day_of_era = shifted - era * 146097;
    const std::int64_t year_of_era = (day_of_era - day_of_era / 1460
        + day_of_era / 36524 - day_of_era / 146096) / 365;
    std::int64_t year = year_of_era + era * 400;
    const std::int64_t day_of_year_march = day_of_era
        - (365 * year_of_era + year_of_era / 4 - year_of_era / 100);
    const std::int64_t month_march = (5 * day_of_year_march + 2) / 153;
    const std::int64_t day = day_of_year_march - (153 * month_march + 2) / 5 + 1;
    const std::int64_t month = month_march + (month_march < 10 ? 3 : -9);
    year += month <= 2;
    constexpr std::int64_t days_before_month[12] =
        {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334};
    const std::int64_t ordinal = days_before_month[month - 1]
        + (month > 2 && is_leap_year(year)) + day;
    year_out = year;
    ordinal_out = ordinal;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t gregorian_daycount_to_ordinal_date(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 2 || length != 1) return -1;
    const std::int64_t offset = input[0];
    if (offset < -146097 || offset > 146097) return -1;
    if (output == nullptr || capacity < 16) return -2;
    std::int64_t year = 0, ordinal = 0;
    decode_offset(offset, year, ordinal);
    store_i64_le(output, 0, year);
    store_i64_le(output, 8, ordinal);
    return 16;
}
