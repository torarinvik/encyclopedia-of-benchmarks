#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxPoints = 8;
constexpr std::int64_t kMaxDistance = 1'000'000;
constexpr std::int64_t kJavaIntMax = 2'147'483'647;
constexpr std::size_t kMaxInputLength = 2 + kMaxPoints * kMaxPoints;
}

extern "C" std::int64_t kcenters(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const std::int64_t pointCount = values[0], centerCount = values[1];
    if (pointCount < 1 || pointCount > kMaxPoints || centerCount < 1 || centerCount > pointCount ||
        length != static_cast<std::size_t>(2 + pointCount * pointCount)) return -1;
    for (std::int64_t row = 0; row < pointCount; ++row) {
        for (std::int64_t column = 0; column < pointCount; ++column) {
            const std::int64_t distance = values[2 + row * pointCount + column];
            if (distance < 0 || distance > kMaxDistance || (row == column && distance != 0) ||
                distance != values[2 + column * pointCount + row]) return -1;
        }
    }

    bool selected[kMaxPoints]{};
    std::int64_t maxDistance[kMaxPoints];
    for (std::int64_t point = 0; point < pointCount; ++point) maxDistance[point] = kJavaIntMax;
    selected[0] = true;
    for (std::int64_t point = 1; point < pointCount; ++point) {
        const std::int64_t distance = values[2 + point];
        if (distance < maxDistance[point]) maxDistance[point] = distance;
    }
    for (std::int64_t center = 1; center < centerCount; ++center) {
        std::int64_t farthest = -1;
        for (std::int64_t point = 0; point < pointCount; ++point)
            if (!selected[point] && (farthest == -1 || maxDistance[point] > maxDistance[farthest])) farthest = point;
        selected[farthest] = true;
        for (std::int64_t point = 0; point < pointCount; ++point) {
            const std::int64_t distance = values[2 + farthest * pointCount + point];
            if (distance < maxDistance[point]) maxDistance[point] = distance;
        }
    }
    std::int64_t result = 0;
    for (std::int64_t point = 0; point < pointCount; ++point)
        if (maxDistance[point] > result) result = maxDistance[point];
    return result;
}
