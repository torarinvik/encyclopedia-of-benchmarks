/* Compute a bounded single-heap subtraction game's Sprague-Grundy number. */
#include <array>
#include <cstddef>
#include <cstdint>

static constexpr std::int64_t MAX_POSITION = 64;
static constexpr std::int64_t MAX_MOVE_COUNT = 32;
static constexpr std::int64_t MAX_MOVE_SIZE = 32;

static std::int64_t calculate_grundy(std::int64_t position,
                                    std::array<std::int64_t, MAX_POSITION + 1>& memo,
                                    const std::int64_t* values,
                                    std::size_t move_count) noexcept
{
    const auto index = static_cast<std::size_t>(position);
    if (memo[index] != -1) return memo[index];
    if (position == 0) {
        memo[0] = 0;
        return 0;
    }

    std::array<bool, MAX_MOVE_COUNT + 1> reachable{};
    for (std::size_t i = 0; i < move_count; ++i) {
        const std::int64_t move = values[2 + i];
        if (move <= position) {
            const std::int64_t child = calculate_grundy(position - move, memo, values, move_count);
            if (child >= 0 && child <= MAX_MOVE_COUNT) reachable[static_cast<std::size_t>(child)] = true;
        }
    }
    std::int64_t mex = 0;
    while (mex <= MAX_MOVE_COUNT && reachable[static_cast<std::size_t>(mex)]) ++mex;
    memo[index] = mex;
    return mex;
}

extern "C" std::int64_t sprague_grundy_theorem(const std::int64_t* values,
                                               std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 2 + MAX_MOVE_COUNT) return -1;
    const std::int64_t position = values[0];
    const std::int64_t move_count_value = values[1];
    if (position < 0 || position > MAX_POSITION ||
        move_count_value < 0 || move_count_value > MAX_MOVE_COUNT) return -1;
    const auto move_count = static_cast<std::size_t>(move_count_value);
    if (length != 2 + move_count) return -1;
    for (std::size_t i = 0; i < move_count; ++i)
        if (values[2 + i] < 1 || values[2 + i] > MAX_MOVE_SIZE) return -1;

    std::array<std::int64_t, MAX_POSITION + 1> memo;
    memo.fill(-1);
    return calculate_grundy(position, memo, values, move_count);
}
