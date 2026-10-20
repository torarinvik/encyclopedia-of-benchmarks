#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

static constexpr std::size_t kInputLength = 7;
static constexpr std::size_t kMaxOutputBytes = 152;
static constexpr std::int64_t kCoordinateScale = 1000000;

static std::int64_t orient(std::int64_t ax, std::int64_t ay, std::int64_t bx,
                           std::int64_t by, std::int64_t cx, std::int64_t cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

static std::int64_t roundRatioAway(std::int64_t numerator, std::int64_t denominator) {
    const std::int64_t magnitude = numerator < 0 ? -numerator : numerator;
    const std::int64_t rounded = (magnitude + denominator / 2) / denominator;
    return numerator < 0 ? -rounded : rounded;
}

static void putI64(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits);
        bits >>= 8;
    }
}

extern "C" std::int64_t delaunay_mesh_refinement(const std::int64_t* values,
                                                  std::size_t length,
                                                  std::uint8_t* output,
                                                  std::size_t capacity) {
    if (values == nullptr || length != kInputLength || values[0] != 3) return -1;
    std::int64_t x[3], y[3];
    for (int i = 0; i < 3; ++i) {
        x[i] = values[1 + 2 * i];
        y[i] = values[2 + 2 * i];
        if (x[i] < -100 || x[i] > 100 || y[i] < -100 || y[i] > 100) return -1;
        for (int j = 0; j < i; ++j) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    const std::int64_t area2 = orient(x[0], y[0], x[1], y[1], x[2], y[2]);
    if (area2 <= 0) return -1;
    for (int i = 0; i < 3; ++i) {
        const int j = (i + 1) % 3, k = (i + 2) % 3;
        const std::int64_t ux = x[j] - x[i], uy = y[j] - y[i];
        const std::int64_t vx = x[k] - x[i], vy = y[k] - y[i];
        if (ux * vx + uy * vy <= 0) return -1;
    }
    const double len01 = std::sqrt(static_cast<double>((x[1]-x[0])*(x[1]-x[0]) + (y[1]-y[0])*(y[1]-y[0])));
    const double len12 = std::sqrt(static_cast<double>((x[2]-x[1])*(x[2]-x[1]) + (y[2]-y[1])*(y[2]-y[1])));
    const double len20 = std::sqrt(static_cast<double>((x[0]-x[2])*(x[0]-x[2]) + (y[0]-y[2])*(y[0]-y[2])));
    const double shortest = std::min(len01, std::min(len12, len20));
    const double ratio = (len01 * len12 * len20) / (2.0 * static_cast<double>(area2) * shortest);
    const double beta = 1.0 / (2.0 * std::sin(3.14159265358979323846 / 9.0));
    const bool refine = ratio > beta * (1.0 + 1e-12);

    std::uint8_t staged[kMaxOutputBytes]{};
    putI64(staged, 0, refine ? 4 : 3);
    for (int i = 0; i < 3; ++i) {
        putI64(staged, 8 + 16 * static_cast<std::size_t>(i), x[i] * kCoordinateScale);
        putI64(staged, 16 + 16 * static_cast<std::size_t>(i), y[i] * kCoordinateScale);
    }
    if (refine) {
        const std::int64_t ax = x[0], ay = y[0];
        const std::int64_t bax = x[1] - ax, bay = y[1] - ay;
        const std::int64_t cax = x[2] - ax, cay = y[2] - ay;
        const std::int64_t denominator = 2 * (bax * cay - bay * cax);
        const std::int64_t balenSq = bax * bax + bay * bay;
        const std::int64_t calenSq = cax * cax + cay * cay;
        const std::int64_t centerXNum = ax * denominator + cay * balenSq - bay * calenSq;
        const std::int64_t centerYNum = ay * denominator + bax * calenSq - cax * balenSq;
        putI64(staged, 56, roundRatioAway(centerXNum * kCoordinateScale, denominator));
        putI64(staged, 64, roundRatioAway(centerYNum * kCoordinateScale, denominator));
        const std::int64_t triangles[] = {3, 0, 1, 3, 1, 2, 3, 2, 0, 3};
        for (std::size_t i = 0; i < 10; ++i) putI64(staged, 72 + 8 * i, triangles[i]);
    } else {
        const std::int64_t triangles[] = {1, 0, 1, 2};
        for (std::size_t i = 0; i < 4; ++i) putI64(staged, 56 + 8 * i, triangles[i]);
    }
    const std::size_t required = refine ? kMaxOutputBytes : 88;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < required; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(required);
}
