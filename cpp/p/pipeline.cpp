#include <cstddef>
#include <cstdint>

extern "C" std::int64_t pipeline(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > 66) return -1;

    const std::int64_t initial = values[0];
    const std::int64_t stage_count = values[1];
    if (initial < 0 || initial > 2 || stage_count < 1 || stage_count > 32) return -1;
    if (length != static_cast<std::size_t>(2 + 2 * stage_count)) return -1;

    std::int64_t result = initial;
    for (std::int64_t index = 0; index < stage_count; ++index) {
        const std::int64_t operation = values[2 + 2 * index];
        const std::int64_t argument = values[3 + 2 * index];
        if (argument < 0 || argument > 2) return -1;
        if (operation == 0) result += argument;
        else if (operation == 1) result *= argument;
        else return -1;
    }
    return result;
}
