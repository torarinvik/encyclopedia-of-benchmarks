#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxSide = 12;
constexpr std::size_t MaxCells = MaxSide * MaxSide;
constexpr std::size_t MaxSamples = MaxCells;
constexpr std::size_t MaxInputLength = 2 + 2 * MaxCells;
constexpr std::size_t MaxParseableInputLength = MaxInputLength + 1;

std::uint16_t sampleCode(const std::int64_t* input, std::size_t base,
                         std::size_t side, std::size_t row,
                         std::size_t column, std::size_t count,
                         std::size_t stride) noexcept {
    std::uint16_t code = 0;
    for (std::size_t offset = 0; offset < count; ++offset) {
        const auto at = base + row * side + column + offset * stride;
        code = static_cast<std::uint16_t>(4 * code + input[at]);
    }
    return code;
}

void putI64LittleEndian(std::uint8_t* output, std::size_t offset,
                        std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffU);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t two_dimensional_optimal_expected_matching(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > MaxParseableInputLength)
        return -1;

    const auto nValue = input[0];
    const auto mValue = input[1];
    if (nValue < 1 || nValue > static_cast<std::int64_t>(MaxSide)
            || mValue < 1 || mValue > nValue)
        return -1;

    const auto n = static_cast<std::size_t>(nValue);
    const auto m = static_cast<std::size_t>(mValue);
    const auto textSize = n * n;
    const auto patternSize = m * m;
    if (length != 2 + textSize + patternSize) return -1;

    const auto patternBase = 2 + textSize;
    for (std::size_t index = 0; index < textSize + patternSize; ++index)
        if (input[2 + index] < 0 || input[2 + index] > 3) return -1;

    std::size_t q = 1;
    std::size_t codeCapacity = 4;
    while (codeCapacity < patternSize) {
        ++q;
        codeCapacity *= 4;
    }
    const auto stride = m / q;
    const auto finalOffset = (q - 1) * stride;

    std::array<std::int16_t, 256> heads{};
    heads.fill(-1);
    std::array<std::int16_t, MaxSamples> next{};
    std::array<std::uint8_t, MaxSamples> addressRow{};
    std::array<std::uint8_t, MaxSamples> addressColumn{};
    std::size_t addressCount = 0;
    for (std::size_t row = 0; row < m; ++row) {
        for (std::size_t residue = 0; residue < stride; ++residue) {
            const auto code = sampleCode(input, patternBase, m, row,
                                         residue, q, stride);
            addressRow[addressCount] = static_cast<std::uint8_t>(row);
            addressColumn[addressCount] = static_cast<std::uint8_t>(residue);
            next[addressCount] = heads[code];
            heads[code] = static_cast<std::int16_t>(addressCount);
            ++addressCount;
        }
    }

    std::array<bool, MaxCells> tested{};
    std::array<bool, MaxCells> matched{};
    const auto rowStarts = n - m + 1;
    const auto columnStarts = n - m + 1;
    for (std::size_t textRow = 0; textRow < n; textRow += m) {
        for (std::size_t textColumn = 0;
             textColumn + finalOffset < n;
             textColumn += stride) {
            const auto code = sampleCode(input, 2, n, textRow,
                                         textColumn, q, stride);
            auto address = heads[code];
            while (address >= 0) {
                const auto slot = static_cast<std::size_t>(address);
                const auto candidateRow = static_cast<std::int64_t>(textRow)
                    - static_cast<std::int64_t>(addressRow[slot]);
                const auto candidateColumn = static_cast<std::int64_t>(textColumn)
                    - static_cast<std::int64_t>(addressColumn[slot]);
                if (candidateRow >= 0 && candidateColumn >= 0
                        && static_cast<std::size_t>(candidateRow) < rowStarts
                        && static_cast<std::size_t>(candidateColumn) < columnStarts) {
                    const auto candidate = static_cast<std::size_t>(candidateRow) * n
                        + static_cast<std::size_t>(candidateColumn);
                    if (!tested[candidate]) {
                        tested[candidate] = true;
                        bool equal = true;
                        for (std::size_t row = 0; row < m && equal; ++row) {
                            for (std::size_t column = 0; column < m; ++column) {
                                const auto textAt = 2
                                    + (static_cast<std::size_t>(candidateRow) + row) * n
                                    + static_cast<std::size_t>(candidateColumn) + column;
                                const auto patternAt = patternBase + row * m + column;
                                if (input[textAt] != input[patternAt]) {
                                    equal = false;
                                    break;
                                }
                            }
                        }
                        matched[candidate] = equal;
                    }
                }
                address = next[slot];
            }
        }
    }

    std::size_t matchCount = 0;
    for (std::size_t row = 0; row < rowStarts; ++row)
        for (std::size_t column = 0; column < columnStarts; ++column)
            if (matched[row * n + column]) ++matchCount;

    const auto outputBytes = 8 * (1 + 2 * matchCount);
    if (output == nullptr || capacity < outputBytes) return -2;

    putI64LittleEndian(output, 0, static_cast<std::int64_t>(matchCount));
    std::size_t outputWord = 1;
    for (std::size_t row = 0; row < rowStarts; ++row) {
        for (std::size_t column = 0; column < columnStarts; ++column) {
            if (!matched[row * n + column]) continue;
            putI64LittleEndian(output, 8 * outputWord++, static_cast<std::int64_t>(row));
            putI64LittleEndian(output, 8 * outputWord++, static_cast<std::int64_t>(column));
        }
    }
    return static_cast<std::int64_t>(outputBytes);
}
