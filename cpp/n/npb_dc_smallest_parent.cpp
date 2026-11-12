/* Bounded clean-room profile of the NAS NPB DC smallest-parent algorithm.
 * Algorithm references: NASA NAS-03-005 and Harinarayan et al., SIGMOD 1996.
 */
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_dims = 5, max_rows = 16, max_masks = 1u << max_dims;
unsigned popcount(unsigned value) { unsigned count = 0; while (value) { count += value & 1u; value >>= 1; } return count; }
bool equal_key(const std::array<std::int64_t, max_dims>& a, const std::array<std::int64_t, max_dims>& b,
               unsigned mask, std::size_t dims) {
    for (std::size_t d = 0; d < dims; ++d) if ((mask & (1u << d)) && a[d] != b[d]) return false;
    return true;
}
bool less_key(const std::array<std::int64_t, max_dims>& a, const std::array<std::int64_t, max_dims>& b,
              unsigned mask, std::size_t dims) {
    for (std::size_t d = 0; d < dims; ++d) if (mask & (1u << d)) {
        if (a[d] < b[d]) return true;
        if (a[d] > b[d]) return false;
    }
    return false;
}
}

extern "C" std::int64_t npb_dc_smallest_parent(const std::int64_t* input, std::size_t length) {
    if (!input || length < 4 || length > 98 || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_dims) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_rows)) return -1;
    const auto dims = static_cast<std::size_t>(input[0]), rows = static_cast<std::size_t>(input[1]);
    if (length != 2 + rows * (dims + 1)) return -1;
    std::array<std::array<std::int64_t, max_dims>, max_rows> attributes{};
    std::array<std::int64_t, max_rows> measures{};
    std::size_t offset = 2;
    for (std::size_t r = 0; r < rows; ++r) {
        for (std::size_t d = 0; d < dims; ++d) {
            const auto value = input[offset++];
            if (value < 0 || value > 7) return -1;
            attributes[r][d] = value;
        }
        measures[r] = input[offset++];
        if (measures[r] < 0 || measures[r] > 1000) return -1;
    }

    using Key = std::array<std::int64_t, max_dims>;
    std::array<std::array<Key, max_rows>, max_masks> keys{};
    std::array<std::array<std::int64_t, max_rows>, max_masks> sums{};
    std::array<std::size_t, max_masks> counts{};
    std::array<int, max_masks> parents{};
    parents.fill(-2);
    const unsigned full = (1u << dims) - 1u;
    parents[full] = -1;
    for (std::size_t r = 0; r < rows; ++r) {
        std::size_t g = 0;
        while (g < counts[full] && !equal_key(keys[full][g], attributes[r], full, dims)) ++g;
        if (g == counts[full]) { keys[full][g] = attributes[r]; sums[full][g] = measures[r]; ++counts[full]; }
        else sums[full][g] += measures[r];
    }
    for (std::size_t i = 1; i < counts[full]; ++i) {
        auto p = i;
        while (p > 0 && less_key(keys[full][p], keys[full][p - 1], full, dims)) {
            keys[full][p].swap(keys[full][p - 1]);
            std::swap(sums[full][p], sums[full][p - 1]);
            --p;
        }
    }
    for (int wanted = static_cast<int>(dims) - 1; wanted >= 0; --wanted) {
        for (unsigned mask = 0; mask <= full; ++mask) {
            if (popcount(mask) != static_cast<unsigned>(wanted)) continue;
            unsigned parent = 0;
            std::size_t best = max_rows + 1;
            bool found = false;
            for (std::size_t d = 0; d < dims; ++d) if (!(mask & (1u << d))) {
                const unsigned candidate = mask | (1u << d);
                if (!found || counts[candidate] < best) { parent = candidate; best = counts[candidate]; found = true; }
            }
            if (!found) return -1;
            parents[mask] = static_cast<int>(parent);
            for (std::size_t pg = 0; pg < counts[parent]; ++pg) {
                std::size_t g = 0;
                while (g < counts[mask] && !equal_key(keys[mask][g], keys[parent][pg], mask, dims)) ++g;
                if (g == counts[mask]) {
                    for (std::size_t d = 0; d < dims; ++d) if (mask & (1u << d)) keys[mask][g][d] = keys[parent][pg][d];
                    sums[mask][g] = sums[parent][pg];
                    ++counts[mask];
                } else sums[mask][g] += sums[parent][pg];
            }
            for (std::size_t i = 1; i < counts[mask]; ++i) {
                auto p = i;
                while (p > 0 && less_key(keys[mask][p], keys[mask][p - 1], mask, dims)) {
                    keys[mask][p].swap(keys[mask][p - 1]);
                    std::swap(sums[mask][p], sums[mask][p - 1]);
                    --p;
                }
            }
        }
    }
    std::int64_t checksum = 0;
    for (unsigned mask = 0; mask <= full; ++mask) {
        const std::int64_t view = static_cast<std::int64_t>(mask) + 1;
        checksum += view * 1000000 + (static_cast<std::int64_t>(parents[mask]) + 2) * 10000 +
                    static_cast<std::int64_t>(counts[mask]) * 1000;
        for (std::size_t g = 0; g < counts[mask]; ++g) {
            const auto rank = static_cast<std::int64_t>(g + 1);
            checksum += rank * (sums[mask][g] + 1);
            for (std::size_t d = 0; d < dims; ++d)
                if (mask & (1u << d)) checksum += rank * static_cast<std::int64_t>(d + 1) * (keys[mask][g][d] + 1);
        }
    }
    return checksum;
}
