#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxDim = 5, MaxPatternDim = 4, MaxMatches = 125, MaxInput = 196;
void put(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
bool sameRows(const std::array<std::int64_t, MaxPatternDim * MaxPatternDim>& plane,
              std::size_t a, std::size_t b, std::size_t width) {
    for (std::size_t c = 0; c < width; ++c)
        if (plane[a * width + c] != plane[b * width + c]) return false;
    return true;
}
}

extern "C" std::int64_t three_dimensional_bird_baker_matching(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 7 || length > MaxInput) return -1;
    const auto r0 = input[0], c0 = input[1], d0 = input[2];
    const auto pr0 = input[3], pc0 = input[4], pd0 = input[5];
    if (r0 < 1 || r0 > 5 || c0 < 1 || c0 > 5 || d0 < 1 || d0 > 5
            || pr0 < 1 || pr0 > 4 || pc0 < 1 || pc0 > 4 || pd0 < 1 || pd0 > 4
            || pr0 > r0 || pc0 > c0 || pd0 > d0) return -1;
    const auto r = static_cast<std::size_t>(r0), c = static_cast<std::size_t>(c0), d = static_cast<std::size_t>(d0);
    const auto pr = static_cast<std::size_t>(pr0), pc = static_cast<std::size_t>(pc0), pd = static_cast<std::size_t>(pd0);
    const auto textSize = r * c * d, patternSize = pr * pc * pd;
    if (length != 6 + textSize + patternSize) return -1;
    std::array<std::int64_t, MaxDim * MaxDim * MaxDim> text{};
    std::array<std::int64_t, MaxPatternDim * MaxPatternDim * MaxPatternDim> pattern{};
    for (std::size_t i = 0; i < textSize; ++i) {
        text[i] = input[6 + i];
        if (text[i] < 0 || text[i] > 3) return -1;
    }
    for (std::size_t i = 0; i < patternSize; ++i) {
        pattern[i] = input[6 + textSize + i];
        if (pattern[i] < 0 || pattern[i] > 3) return -1;
    }

    std::array<std::size_t, MaxPatternDim> planeId{};
    std::array<std::array<std::int64_t, MaxPatternDim * MaxPatternDim>, MaxPatternDim> uniquePlanes{};
    std::size_t uniqueCount = 0, planeArea = pr * pc;
    for (std::size_t z = 0; z < pd; ++z) {
        std::size_t found = uniqueCount;
        for (std::size_t candidate = 0; candidate < uniqueCount; ++candidate) {
            bool equal = true;
            for (std::size_t i = 0; i < planeArea; ++i)
                if (uniquePlanes[candidate][i] != pattern[z * planeArea + i]) equal = false;
            if (equal) { found = candidate; break; }
        }
        if (found == uniqueCount) {
            for (std::size_t i = 0; i < planeArea; ++i) uniquePlanes[uniqueCount][i] = pattern[z * planeArea + i];
            ++uniqueCount;
        }
        planeId[z] = found;
    }

    const auto rowStarts = r - pr + 1, columnStarts = c - pc + 1;
    std::array<std::array<std::array<std::int8_t, MaxDim>, MaxDim>, MaxDim> labels{};
    for (auto& plane : labels) for (auto& row : plane) row.fill(-1);
    for (std::size_t z = 0; z < d; ++z) {
        for (std::size_t unique = 0; unique < uniqueCount; ++unique) {
            std::array<std::array<std::array<bool, MaxPatternDim>, MaxDim>, MaxDim> marks{};
            std::array<std::size_t, MaxPatternDim> prefix{};
            for (std::size_t i = 1; i < pr; ++i) {
                auto matched = prefix[i - 1];
                while (matched > 0 && !sameRows(uniquePlanes[unique], i, matched, pc)) matched = prefix[matched - 1];
                if (sameRows(uniquePlanes[unique], i, matched, pc)) ++matched;
                prefix[i] = matched;
            }
            for (std::size_t row = 0; row < r; ++row)
                for (std::size_t col = 0; col < columnStarts; ++col)
                    for (std::size_t pRow = 0; pRow < pr; ++pRow) {
                        bool equal = true;
                        for (std::size_t pCol = 0; pCol < pc; ++pCol)
                            if (text[(z * r + row) * c + col + pCol] != uniquePlanes[unique][pRow * pc + pCol]) equal = false;
                        marks[row][col][pRow] = equal;
                    }
            for (std::size_t col = 0; col < columnStarts; ++col) {
                std::size_t matched = 0;
                for (std::size_t row = 0; row < r; ++row) {
                    while (matched > 0 && !marks[row][col][matched]) matched = prefix[matched - 1];
                    if (marks[row][col][matched]) ++matched;
                    if (matched == pr) {
                        labels[z][row + 1 - pr][col] = static_cast<std::int8_t>(unique);
                        matched = prefix[matched - 1];
                    }
                }
            }
        }
    }

    std::array<std::size_t, MaxPatternDim> prefix{};
    for (std::size_t i = 1; i < pd; ++i) {
        auto matched = prefix[i - 1];
        while (matched > 0 && planeId[i] != planeId[matched]) matched = prefix[matched - 1];
        if (planeId[i] == planeId[matched]) ++matched;
        prefix[i] = matched;
    }
    std::array<std::array<std::int64_t, 3>, MaxMatches> matches{};
    std::size_t count = 0;
    for (std::size_t row = 0; row < rowStarts; ++row)
        for (std::size_t col = 0; col < columnStarts; ++col) {
            std::size_t matched = 0;
            for (std::size_t z = 0; z < d; ++z) {
                const auto label = labels[z][row][col];
                while (matched > 0 && label != static_cast<std::int8_t>(planeId[matched])) matched = prefix[matched - 1];
                if (label == static_cast<std::int8_t>(planeId[matched])) ++matched;
                if (matched == pd) {
                    matches[count++] = {static_cast<std::int64_t>(row), static_cast<std::int64_t>(col), static_cast<std::int64_t>(z + 1 - pd)};
                    matched = prefix[matched - 1];
                }
            }
        }
    const auto bytes = 8 * (1 + 3 * count);
    if (output == nullptr || capacity < bytes) return -2;
    put(output, 0, static_cast<std::int64_t>(count));
    for (std::size_t i = 0; i < count; ++i)
        for (std::size_t axis = 0; axis < 3; ++axis)
            put(output, 8 * (1 + 3 * i + axis), matches[i][axis]);
    return static_cast<std::int64_t>(bytes);
}
