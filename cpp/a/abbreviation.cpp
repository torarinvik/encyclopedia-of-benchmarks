#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_STRING_LENGTH = 128;

bool is_lower_ascii(std::int64_t value)
{
    return value >= 'a' && value <= 'z';
}

std::int64_t uppercase_ascii(std::int64_t value)
{
    return is_lower_ascii(value) ? value - ('a' - 'A') : value;
}
}

// Check whether lowercase source letters can be capitalized or deleted.
extern "C" std::int64_t abbreviation(const std::int64_t *values, std::size_t length)
{
    if (length < 2 || length > 2 + 2 * MAX_STRING_LENGTH) return -1;
    const std::int64_t source_length = values[0];
    const std::int64_t target_length = values[1];
    if (source_length < 0 || source_length > static_cast<std::int64_t>(MAX_STRING_LENGTH) ||
        target_length < 0 || target_length > static_cast<std::int64_t>(MAX_STRING_LENGTH) ||
        length != static_cast<std::size_t>(2 + source_length + target_length)) return -1;
    for (std::int64_t index = 0; index < source_length; ++index) {
        const std::int64_t value = values[2 + static_cast<std::size_t>(index)];
        if (!((value >= 'A' && value <= 'Z') || is_lower_ascii(value))) return -1;
    }
    for (std::int64_t index = 0; index < target_length; ++index) {
        const std::int64_t value = values[2 + static_cast<std::size_t>(source_length) +
                                          static_cast<std::size_t>(index)];
        if (value < 'A' || value > 'Z') return -1;
    }

    bool current[MAX_STRING_LENGTH + 1] = {};
    bool next[MAX_STRING_LENGTH + 1] = {};
    current[0] = true;
    for (std::int64_t source_index = 0; source_index < source_length; ++source_index) {
        for (std::int64_t target_index = 0; target_index <= target_length; ++target_index)
            next[target_index] = false;
        const std::int64_t source = values[2 + static_cast<std::size_t>(source_index)];
        const std::int64_t upper = uppercase_ascii(source);
        for (std::int64_t target_index = 0; target_index <= target_length; ++target_index) {
            if (!current[target_index]) continue;
            if (is_lower_ascii(source)) next[target_index] = true;
            if (target_index < target_length &&
                upper == values[2 + static_cast<std::size_t>(source_length) +
                                static_cast<std::size_t>(target_index)])
                next[target_index + 1] = true;
        }
        for (std::int64_t target_index = 0; target_index <= target_length; ++target_index)
            current[target_index] = next[target_index];
    }
    return current[target_length] ? 1 : 0;
}
