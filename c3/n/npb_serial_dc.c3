/* NAS Parallel Benchmarks 3.3 DC source notice:
 * Permission to use, copy, distribute and modify this software for any purpose
 * with or without fee is hereby granted. We request, however, that all derived
 * work reference the NAS Parallel Benchmarks 3.3. This software is provided
 * "as is" without express or implied warranty.
 *
 * Clean-room bounded adaptation: packed input and ordered scalar checksum
 * replace generated files and the original memory management harness.
 */
module npb_serial_dc;

const int MAX_DIMS = 5;
const int MAX_ROWS = 16;

fn long npb_serial_dc(long* input, usz length) @export("npb_serial_dc") {
    if (input == null || length < 4 || input[0] < 1 || input[0] > MAX_DIMS || input[1] < 1 || input[1] > MAX_ROWS) return -1;
    usz dimensions = (usz)input[0], rows = (usz)input[1];
    if (length != 2 + rows * (dimensions + 1)) return -1;
    long[MAX_ROWS][MAX_DIMS] attributes = zeroed;
    long[MAX_ROWS] measures = zeroed;
    usz offset = 2;
    for (usz row = 0; row < rows; row++) {
        for (usz dimension = 0; dimension < dimensions; dimension++) {
            long value = input[offset]; offset++;
            if (value < 0 || value > 7) return -1;
            attributes[row][dimension] = value;
        }
        measures[row] = input[offset]; offset++;
        if (measures[row] < 0 || measures[row] > 1000) return -1;
    }

    long checksum = 0;
    int view_limit = 1 << (int)dimensions;
    for (int mask = 1; mask < view_limit; mask++) {
        long[MAX_ROWS][MAX_DIMS] keys = zeroed;
        long[MAX_ROWS] sums = zeroed;
        usz group_count = 0;
        for (usz row = 0; row < rows; row++) {
            usz group = 0;
            for (; group < group_count; group++) {
                bool equal = true;
                for (usz dimension = 0; dimension < dimensions; dimension++) {
                    if ((mask & (1 << (int)dimension)) != 0 && keys[group][dimension] != attributes[row][dimension]) equal = false;
                }
                if (equal) break;
            }
            if (group == group_count) {
                for (usz dimension = 0; dimension < dimensions; dimension++)
                    if ((mask & (1 << (int)dimension)) != 0) keys[group][dimension] = attributes[row][dimension];
                sums[group] = measures[row]; group_count++;
            } else sums[group] += measures[row];
        }
        for (usz index = 1; index < group_count; index++) {
            usz position = index;
            while (position > 0) {
                int comparison = 0;
                for (usz dimension = 0; dimension < dimensions; dimension++) {
                    if ((mask & (1 << (int)dimension)) == 0) continue;
                    if (keys[position][dimension] < keys[position - 1][dimension]) { comparison = -1; break; }
                    if (keys[position][dimension] > keys[position - 1][dimension]) { comparison = 1; break; }
                }
                if (comparison >= 0) break;
                for (usz dimension = 0; dimension < dimensions; dimension++) {
                    long temporary = keys[position][dimension]; keys[position][dimension] = keys[position - 1][dimension]; keys[position - 1][dimension] = temporary;
                }
                long temporary_sum = sums[position]; sums[position] = sums[position - 1]; sums[position - 1] = temporary_sum;
                position--;
            }
        }
        long view = (long)mask;
        checksum += view * 1009 + (long)group_count * 9176;
        for (usz group = 0; group < group_count; group++) {
            checksum += (view + 1) * (long)(group + 1) * (sums[group] + 13);
            for (usz dimension = 0; dimension < dimensions; dimension++)
                if ((mask & (1 << (int)dimension)) != 0)
                    checksum += (long)(dimension + 1) * (keys[group][dimension] + 1) * (long)(group + 3) * (view + 5);
        }
    }
    return checksum;
}
