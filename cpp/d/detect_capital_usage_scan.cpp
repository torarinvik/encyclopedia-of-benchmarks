#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 1024; }
static bool is_upper(std::int64_t value) { return value >= 65 && value <= 90; }
static bool is_lower(std::int64_t value) { return value >= 97 && value <= 122; }
static bool valid_input(const std::int64_t *input, std::size_t length) {
    if (length > max_length || (length != 0 && input == nullptr)) return false;
    for (std::size_t index = 0; index < length; ++index)
        if (!is_upper(input[index]) && !is_lower(input[index])) return false;
    return true;
}

// Recheck the whole word for every uppercase byte after the first.
extern "C" std::int64_t detect_capital_usage_scan(const std::int64_t *input,
    std::size_t length) noexcept {
    if (!valid_input(input, length)) return -1;
    for (std::size_t index = 1; index < length; ++index) {
        if (is_upper(input[index])) {
            bool all_upper = true;
            for (std::size_t check = 0; check < length; ++check) {
                if (is_lower(input[check])) { all_upper = false; break; }
            }
            if (!all_upper) return 0;
        }
    }
    return 1;
}
