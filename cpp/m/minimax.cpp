#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::int64_t kMaxLeaves = 32;
constexpr std::size_t kMaxInputLength = 2 + kMaxLeaves;
constexpr std::int64_t kInvalidResult = -2'147'483'649;

std::int64_t evaluate(const std::int64_t *values, std::size_t index, std::size_t depth,
                      std::size_t height, bool maximizing) {
    if (depth == height) return values[2 + index];
    const std::int64_t left = evaluate(values, index * 2, depth + 1, height, !maximizing);
    const std::int64_t right = evaluate(values, index * 2 + 1, depth + 1, height, !maximizing);
    return maximizing ? (left > right ? left : right) : (left < right ? left : right);
}
}

extern "C" std::int64_t minimax(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > kMaxInputLength) return kInvalidResult;
    const std::int64_t leafCount = values[0], firstTurnIsMax = values[1];
    if (leafCount < 1 || leafCount > kMaxLeaves || (leafCount & (leafCount - 1)) != 0 ||
        (firstTurnIsMax != 0 && firstTurnIsMax != 1) ||
        length != static_cast<std::size_t>(2 + leafCount)) return kInvalidResult;
    for (std::int64_t leaf = 0; leaf < leafCount; ++leaf)
        if (values[2 + leaf] < std::numeric_limits<std::int32_t>::min() ||
            values[2 + leaf] > std::numeric_limits<std::int32_t>::max()) return kInvalidResult;

    std::size_t height = 0;
    for (std::int64_t width = leafCount; width > 1; width /= 2) ++height;
    return evaluate(values, 0, 0, height, firstTurnIsMax == 1);
}
