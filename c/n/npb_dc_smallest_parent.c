/* Bounded clean-room profile of the NAS NPB DC smallest-parent algorithm.
 * Algorithm references: NASA NAS-03-005 and Harinarayan et al., SIGMOD 1996.
 */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_DIMS = 5, MAX_ROWS = 16, MAX_MASKS = 1 << MAX_DIMS };

static unsigned popcount(unsigned value)
{
    unsigned count = 0;
    while (value != 0) { count += value & 1u; value >>= 1; }
    return count;
}

static bool key_equal(const int64_t left[MAX_DIMS], const int64_t right[MAX_DIMS], unsigned mask, size_t dimensions)
{
    for (size_t dimension = 0; dimension < dimensions; ++dimension)
        if ((mask & (1u << dimension)) != 0 && left[dimension] != right[dimension]) return false;
    return true;
}

static bool key_less(const int64_t left[MAX_DIMS], const int64_t right[MAX_DIMS], unsigned mask, size_t dimensions)
{
    for (size_t dimension = 0; dimension < dimensions; ++dimension) {
        if ((mask & (1u << dimension)) == 0) continue;
        if (left[dimension] < right[dimension]) return true;
        if (left[dimension] > right[dimension]) return false;
    }
    return false;
}

int64_t npb_dc_smallest_parent(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || length > 98 || input[0] < 1 || input[0] > MAX_DIMS ||
        input[1] < 1 || input[1] > MAX_ROWS) return -1;
    const size_t dimensions = (size_t)input[0], row_count = (size_t)input[1];
    if (length != 2 + row_count * (dimensions + 1)) return -1;

    int64_t attributes[MAX_ROWS][MAX_DIMS] = {{0}}, measures[MAX_ROWS] = {0};
    size_t offset = 2;
    for (size_t row = 0; row < row_count; ++row) {
        for (size_t dimension = 0; dimension < dimensions; ++dimension) {
            const int64_t value = input[offset++];
            if (value < 0 || value > 7) return -1;
            attributes[row][dimension] = value;
        }
        measures[row] = input[offset++];
        if (measures[row] < 0 || measures[row] > 1000) return -1;
    }

    int64_t keys[MAX_MASKS][MAX_ROWS][MAX_DIMS] = {{{0}}};
    int64_t sums[MAX_MASKS][MAX_ROWS] = {{0}};
    size_t group_counts[MAX_MASKS] = {0};
    int parents[MAX_MASKS];
    for (size_t mask = 0; mask < MAX_MASKS; ++mask) parents[mask] = -2;
    const unsigned full_mask = (1u << dimensions) - 1u;
    parents[full_mask] = -1;

    /* The full-dimensional view is the sole view grouped directly from rows. */
    for (size_t row = 0; row < row_count; ++row) {
        size_t group = 0;
        while (group < group_counts[full_mask] &&
               !key_equal(keys[full_mask][group], attributes[row], full_mask, dimensions)) ++group;
        if (group == group_counts[full_mask]) {
            for (size_t dimension = 0; dimension < dimensions; ++dimension)
                keys[full_mask][group][dimension] = attributes[row][dimension];
            sums[full_mask][group] = measures[row];
            ++group_counts[full_mask];
        } else sums[full_mask][group] += measures[row];
    }
    for (size_t index = 1; index < group_counts[full_mask]; ++index) {
        size_t position = index;
        while (position > 0 && key_less(keys[full_mask][position], keys[full_mask][position - 1], full_mask, dimensions)) {
            for (size_t dimension = 0; dimension < dimensions; ++dimension) {
                const int64_t temporary = keys[full_mask][position][dimension];
                keys[full_mask][position][dimension] = keys[full_mask][position - 1][dimension];
                keys[full_mask][position - 1][dimension] = temporary;
            }
            const int64_t temporary_sum = sums[full_mask][position];
            sums[full_mask][position] = sums[full_mask][position - 1];
            sums[full_mask][position - 1] = temporary_sum;
            --position;
        }
    }

    for (int wanted = (int)dimensions - 1; wanted >= 0; --wanted) {
        for (unsigned mask = 0; mask <= full_mask; ++mask) {
            if (popcount(mask) != (unsigned)wanted) continue;
            unsigned parent = 0;
            size_t best_count = MAX_ROWS + 1;
            bool found = false;
            for (size_t dimension = 0; dimension < dimensions; ++dimension) {
                const unsigned bit = 1u << dimension;
                if ((mask & bit) != 0) continue;
                const unsigned candidate = mask | bit;
                if (!found || group_counts[candidate] < best_count) {
                    parent = candidate;
                    best_count = group_counts[candidate];
                    found = true;
                }
            }
            if (!found) return -1;
            parents[mask] = (int)parent;
            for (size_t parent_group = 0; parent_group < group_counts[parent]; ++parent_group) {
                size_t group = 0;
                while (group < group_counts[mask] &&
                       !key_equal(keys[mask][group], keys[parent][parent_group], mask, dimensions)) ++group;
                if (group == group_counts[mask]) {
                    for (size_t dimension = 0; dimension < dimensions; ++dimension)
                        if ((mask & (1u << dimension)) != 0)
                            keys[mask][group][dimension] = keys[parent][parent_group][dimension];
                    sums[mask][group] = sums[parent][parent_group];
                    ++group_counts[mask];
                } else sums[mask][group] += sums[parent][parent_group];
            }
            for (size_t index = 1; index < group_counts[mask]; ++index) {
                size_t position = index;
                while (position > 0 && key_less(keys[mask][position], keys[mask][position - 1], mask, dimensions)) {
                    for (size_t dimension = 0; dimension < dimensions; ++dimension) {
                        const int64_t temporary = keys[mask][position][dimension];
                        keys[mask][position][dimension] = keys[mask][position - 1][dimension];
                        keys[mask][position - 1][dimension] = temporary;
                    }
                    const int64_t temporary_sum = sums[mask][position];
                    sums[mask][position] = sums[mask][position - 1];
                    sums[mask][position - 1] = temporary_sum;
                    --position;
                }
            }
        }
    }

    int64_t checksum = 0;
    for (unsigned mask = 0; mask <= full_mask; ++mask) {
        const int64_t view = (int64_t)mask + 1;
        checksum += view * 1000000 + ((int64_t)parents[mask] + 2) * 10000 + (int64_t)group_counts[mask] * 1000;
        size_t rank = 1;
        for (size_t group = 0; group < group_counts[mask]; ++group, ++rank) {
            checksum += (int64_t)rank * (sums[mask][group] + 1);
            for (size_t dimension = 0; dimension < dimensions; ++dimension)
                if ((mask & (1u << dimension)) != 0)
                    checksum += (int64_t)rank * (int64_t)(dimension + 1) * (keys[mask][group][dimension] + 1);
        }
    }
    return checksum;
}
