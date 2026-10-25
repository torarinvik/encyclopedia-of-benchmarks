/* NAS Parallel Benchmarks 3.3 DC source notice:
 * Permission to use, copy, distribute and modify this software for any purpose
 * with or without fee is hereby granted. We request, however, that all derived
 * work reference the NAS Parallel Benchmarks 3.3. This software is provided
 * "as is" without express or implied warranty.
 *
 * Clean-room bounded adaptation: replace generated files and the NPB memory
 * management harness with a packed input and an ordered scalar checksum.
 */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_DIMS = 5, MAX_ROWS = 16 };

int64_t npb_serial_dc(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || input[0] < 1 || input[0] > MAX_DIMS ||
        input[1] < 1 || input[1] > MAX_ROWS) return -1;
    const size_t dimensions = (size_t)input[0];
    const size_t rows = (size_t)input[1];
    if (length != 2 + rows * (dimensions + 1)) return -1;

    int64_t attributes[MAX_ROWS][MAX_DIMS] = {{0}};
    int64_t measures[MAX_ROWS] = {0};
    size_t offset = 2;
    for (size_t row = 0; row < rows; ++row) {
        for (size_t dimension = 0; dimension < dimensions; ++dimension) {
            const int64_t value = input[offset++];
            if (value < 0 || value > 7) return -1;
            attributes[row][dimension] = value;
        }
        measures[row] = input[offset++];
        if (measures[row] < 0 || measures[row] > 1000) return -1;
    }

    int64_t checksum = 0;
    const unsigned view_limit = 1u << dimensions;
    for (unsigned mask = 1; mask < view_limit; ++mask) {
        int64_t keys[MAX_ROWS][MAX_DIMS] = {{0}};
        int64_t sums[MAX_ROWS] = {0};
        size_t group_count = 0;
        for (size_t row = 0; row < rows; ++row) {
            size_t group = 0;
            for (; group < group_count; ++group) {
                bool equal = true;
                for (size_t dimension = 0; dimension < dimensions; ++dimension) {
                    if ((mask & (1u << dimension)) != 0 &&
                        keys[group][dimension] != attributes[row][dimension]) equal = false;
                }
                if (equal) break;
            }
            if (group == group_count) {
                for (size_t dimension = 0; dimension < dimensions; ++dimension)
                    if ((mask & (1u << dimension)) != 0)
                        keys[group][dimension] = attributes[row][dimension];
                sums[group] = measures[row];
                ++group_count;
            } else {
                sums[group] += measures[row];
            }
        }

        for (size_t index = 1; index < group_count; ++index) {
            size_t position = index;
            while (position > 0) {
                int comparison = 0;
                for (size_t dimension = 0; dimension < dimensions; ++dimension) {
                    if ((mask & (1u << dimension)) == 0) continue;
                    if (keys[position][dimension] < keys[position - 1][dimension]) { comparison = -1; break; }
                    if (keys[position][dimension] > keys[position - 1][dimension]) { comparison = 1; break; }
                }
                if (comparison >= 0) break;
                for (size_t dimension = 0; dimension < dimensions; ++dimension) {
                    const int64_t temporary = keys[position][dimension];
                    keys[position][dimension] = keys[position - 1][dimension];
                    keys[position - 1][dimension] = temporary;
                }
                const int64_t temporary_sum = sums[position];
                sums[position] = sums[position - 1];
                sums[position - 1] = temporary_sum;
                --position;
            }
        }

        const int64_t view = (int64_t)mask;
        checksum += view * 1009 + (int64_t)group_count * 9176;
        for (size_t group = 0; group < group_count; ++group) {
            checksum += (view + 1) * (int64_t)(group + 1) * (sums[group] + 13);
            for (size_t dimension = 0; dimension < dimensions; ++dimension)
                if ((mask & (1u << dimension)) != 0)
                    checksum += (int64_t)(dimension + 1) * (keys[group][dimension] + 1) *
                                (int64_t)(group + 3) * (view + 5);
        }
    }
    return checksum;
}
