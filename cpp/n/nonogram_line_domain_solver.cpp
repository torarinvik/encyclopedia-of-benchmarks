#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_side = 8;
constexpr std::size_t line_slots = 16;
struct Domains { std::uint64_t words[line_slots][4]{}; };

bool matches(std::uint32_t mask, std::size_t length, const std::int64_t* clue,
             std::size_t count) noexcept {
    std::size_t found = 0, run = 0;
    for (std::size_t bit = 0; bit < length; ++bit) {
        if ((mask >> bit) & 1U) ++run;
        else if (run != 0) {
            if (found >= count || clue[found] != static_cast<std::int64_t>(run)) return false;
            ++found; run = 0;
        }
    }
    if (run != 0) {
        if (found >= count || clue[found] != static_cast<std::int64_t>(run)) return false;
        ++found;
    }
    return found == count;
}

bool has(const Domains& domains, std::size_t line, std::uint32_t mask) noexcept {
    return (domains.words[line][mask >> 6] & (std::uint64_t{1} << (mask & 63))) != 0;
}
void add(Domains& domains, std::size_t line, std::uint32_t mask) noexcept {
    domains.words[line][mask >> 6] |= std::uint64_t{1} << (mask & 63);
}
std::size_t count(const Domains& domains, std::size_t line, std::size_t length) noexcept {
    std::size_t total = 0;
    for (std::uint32_t mask = 0; mask < (1U << length); ++mask) total += has(domains, line, mask);
    return total;
}
bool filter(Domains& domains, std::size_t line, std::size_t length, std::size_t pos,
            bool allow_zero, bool allow_one) noexcept {
    bool changed = false;
    for (std::uint32_t mask = 0; mask < (1U << length); ++mask) {
        if (!has(domains, line, mask)) continue;
        const bool one = ((mask >> pos) & 1U) != 0;
        if (one ? allow_one : allow_zero) continue;
        domains.words[line][mask >> 6] &= ~(std::uint64_t{1} << (mask & 63));
        changed = true;
    }
    return changed;
}
bool support(const Domains& domains, std::size_t line, std::size_t length,
             std::size_t pos, bool& zero, bool& one) noexcept {
    zero = one = false;
    for (std::uint32_t mask = 0; mask < (1U << length); ++mask) {
        if (!has(domains, line, mask)) continue;
        (((mask >> pos) & 1U) ? one : zero) = true;
    }
    return zero || one;
}
bool propagate(Domains& domains, std::size_t height, std::size_t width) noexcept {
    bool changed;
    do {
        changed = false;
        for (std::size_t row = 0; row < height; ++row) {
            for (std::size_t col = 0; col < width; ++col) {
                bool rz, ro, cz, co;
                if (!support(domains, row, width, col, rz, ro) ||
                    !support(domains, height + col, height, row, cz, co)) return false;
                changed |= filter(domains, row, width, col, cz, co);
                changed |= filter(domains, height + col, height, row, rz, ro);
                if (count(domains, row, width) == 0 || count(domains, height + col, height) == 0) return false;
            }
        }
    } while (changed);
    return true;
}
bool search(Domains& domains, std::size_t height, std::size_t width) noexcept {
    if (!propagate(domains, height, width)) return false;
    std::size_t branch = height;
    for (std::size_t row = 0; row < height; ++row)
        if (count(domains, row, width) > 1) { branch = row; break; }
    if (branch == height) return true;
    for (std::uint32_t mask = 0; mask < (1U << width); ++mask) {
        if (!has(domains, branch, mask)) continue;
        Domains trial = domains;
        for (auto& word : trial.words[branch]) word = 0;
        add(trial, branch, mask);
        if (search(trial, height, width)) { domains = trial; return true; }
    }
    return false;
}
bool parse(const std::int64_t* input, std::size_t length, std::size_t& height,
           std::size_t& width, std::int64_t clues[line_slots][max_side],
           std::size_t counts[line_slots]) noexcept {
    if (input == nullptr || length < 2 || input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > 8) return false;
    height = static_cast<std::size_t>(input[0]); width = static_cast<std::size_t>(input[1]);
    if (length != 2 + 5 * height + 5 * width) return false;
    std::memset(clues, 0, sizeof(std::int64_t) * line_slots * max_side);
    std::memset(counts, 0, sizeof(std::size_t) * line_slots);
    std::size_t offset = 2;
    for (std::size_t group = 0; group < 2; ++group) {
        const auto lines = group == 0 ? height : width;
        const auto line_length = group == 0 ? width : height;
        for (std::size_t line = 0; line < lines; ++line) {
            const auto index = group == 0 ? line : height + line;
            const auto raw_count = input[offset++];
            if (raw_count < 0 || raw_count > 4) return false;
            counts[index] = static_cast<std::size_t>(raw_count);
            std::int64_t needed = raw_count == 0 ? 0 : raw_count - 1;
            for (std::size_t run = 0; run < 4; ++run) {
                const auto value = input[offset++];
                if (run < counts[index]) {
                    if (value <= 0 || value > static_cast<std::int64_t>(line_length)) return false;
                    clues[index][run] = value; needed += value;
                } else if (value != 0) return false;
            }
            if (needed > static_cast<std::int64_t>(line_length)) return false;
        }
    }
    std::int64_t rows = 0, cols = 0;
    for (std::size_t r = 0; r < height; ++r) for (std::size_t k = 0; k < counts[r]; ++k) rows += clues[r][k];
    for (std::size_t c = 0; c < width; ++c) for (std::size_t k = 0; k < counts[height + c]; ++k) cols += clues[height + c][k];
    return rows == cols;
}
}

extern "C" std::int64_t nonogram_line_domain_solver(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    std::size_t height = 0, width = 0;
    std::int64_t clues[line_slots][max_side]{};
    std::size_t counts[line_slots]{};
    if (!parse(input, length, height, width, clues, counts)) return -1;
    Domains domains{};
    for (std::size_t row = 0; row < height; ++row)
        for (std::uint32_t mask = 0; mask < (1U << width); ++mask)
            if (matches(mask, width, clues[row], counts[row])) add(domains, row, mask);
    for (std::size_t col = 0; col < width; ++col)
        for (std::uint32_t mask = 0; mask < (1U << height); ++mask)
            if (matches(mask, height, clues[height + col], counts[height + col])) add(domains, height + col, mask);
    for (std::size_t row = 0; row < height; ++row) if (count(domains, row, width) == 0) return -1;
    for (std::size_t col = 0; col < width; ++col) if (count(domains, height + col, height) == 0) return -1;
    if (!search(domains, height, width)) return -1;
    const auto required = height * width;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t row = 0; row < height; ++row) {
        std::uint32_t mask = 0;
        while (mask < (1U << width) && !has(domains, row, mask)) ++mask;
        for (std::size_t col = 0; col < width; ++col) output[row * width + col] = (mask >> col) & 1U;
    }
    return static_cast<std::int64_t>(required);
}
