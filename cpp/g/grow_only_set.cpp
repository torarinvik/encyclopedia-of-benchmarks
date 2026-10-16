#include <cstddef>
#include <cstdint>

extern "C" std::int64_t grow_only_set(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 1 || length > 25) return -1;
    const auto count_value = values[0];
    if (count_value < 0 || count_value > 12 || length != 1 + 2 * static_cast<std::size_t>(count_value)) return -1;
    std::uint32_t left = 0, right = 0;
    std::uint64_t answers = 0;
    unsigned query_count = 0;
    for (std::int64_t index = 0; index < count_value; ++index) {
        const auto opcode = values[1 + 2 * static_cast<std::size_t>(index)];
        const auto argument = values[2 + 2 * static_cast<std::size_t>(index)];
        if (opcode < 0 || opcode > 7) return -1;
        if (opcode <= 3) {
            if (argument < 0 || argument > 15) return -1;
        } else if (argument != 0) return -1;
        const std::uint32_t bit = opcode <= 3 ? (std::uint32_t{1} << static_cast<unsigned>(argument)) : 0;
        if (opcode == 0) left |= bit;
        else if (opcode == 1) right |= bit;
        else if (opcode == 2 || opcode == 3) {
            const auto set = opcode == 2 ? left : right;
            if (set & bit) answers |= std::uint64_t{1} << query_count;
            ++query_count;
        } else if (opcode == 4) {
            if ((left & right) == left) answers |= std::uint64_t{1} << query_count;
            ++query_count;
        } else if (opcode == 5) {
            if ((left & right) == right) answers |= std::uint64_t{1} << query_count;
            ++query_count;
        } else if (opcode == 6) left |= right;
        else right |= left;
    }
    return static_cast<std::int64_t>(answers | (static_cast<std::uint64_t>(left) << 12) |
                                     (static_cast<std::uint64_t>(right) << 28) |
                                     (static_cast<std::uint64_t>(query_count) << 44));
}
