/* Bounded clean-room NASA NPB DC smallest-parent profile; see NAS-03-005. */
module npb_dc_smallest_parent;

const int MAX_DIMS = 5;
const int MAX_ROWS = 16;
const int MAX_MASKS = 32;

fn long npb_dc_smallest_parent(long* input, usz length) @export("npb_dc_smallest_parent") {
    if (input == null || length < 4 || length > 98 || input[0] < 1 || input[0] > MAX_DIMS || input[1] < 1 || input[1] > MAX_ROWS) return -1;
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

    long[MAX_MASKS][MAX_ROWS][MAX_DIMS] keys = zeroed;
    long[MAX_MASKS][MAX_ROWS] sums = zeroed;
    usz[MAX_MASKS] counts = zeroed;
    int[MAX_MASKS] parents = zeroed;
    for (int mask = 0; mask < MAX_MASKS; mask++) parents[mask] = -2;
    int full = (1 << (int)dimensions) - 1;
    parents[full] = -1;
    for (usz row = 0; row < rows; row++) {
        usz group = 0;
        while (group < counts[full]) {
            bool equal = true;
            for (usz dimension = 0; dimension < dimensions; dimension++)
                if ((full & (1 << (int)dimension)) != 0 && keys[full][group][dimension] != attributes[row][dimension]) equal = false;
            if (equal) break;
            group++;
        }
        if (group == counts[full]) {
            for (usz dimension = 0; dimension < dimensions; dimension++) keys[full][group][dimension] = attributes[row][dimension];
            sums[full][group] = measures[row]; counts[full]++;
        } else sums[full][group] += measures[row];
    }
    for (usz index = 1; index < counts[full]; index++) {
        usz position = index;
        while (position > 0) {
            bool less = false;
            for (usz dimension = 0; dimension < dimensions; dimension++) {
                if (keys[full][position][dimension] < keys[full][position - 1][dimension]) { less = true; break; }
                if (keys[full][position][dimension] > keys[full][position - 1][dimension]) break;
            }
            if (!less) break;
            for (usz dimension = 0; dimension < dimensions; dimension++) {
                long temporary = keys[full][position][dimension]; keys[full][position][dimension] = keys[full][position - 1][dimension]; keys[full][position - 1][dimension] = temporary;
            }
            long temporary_sum = sums[full][position]; sums[full][position] = sums[full][position - 1]; sums[full][position - 1] = temporary_sum;
            position--;
        }
    }

    for (int wanted = (int)dimensions - 1; wanted >= 0; wanted--) {
        for (int mask = 0; mask <= full; mask++) {
            int bits = mask, count_bits = 0;
            while (bits != 0) { count_bits += bits & 1; bits >>= 1; }
            if (count_bits != wanted) continue;
            int parent = -1;
            usz best = MAX_ROWS + 1;
            for (usz dimension = 0; dimension < dimensions; dimension++) {
                int bit = 1 << (int)dimension;
                if ((mask & bit) != 0) continue;
                int candidate = mask | bit;
                if (parent < 0 || counts[candidate] < best) { parent = candidate; best = counts[candidate]; }
            }
            if (parent < 0) return -1;
            parents[mask] = parent;
            for (usz parent_group = 0; parent_group < counts[parent]; parent_group++) {
                usz group = 0;
                while (group < counts[mask]) {
                    bool equal = true;
                    for (usz dimension = 0; dimension < dimensions; dimension++)
                        if ((mask & (1 << (int)dimension)) != 0 && keys[mask][group][dimension] != keys[parent][parent_group][dimension]) equal = false;
                    if (equal) break;
                    group++;
                }
                if (group == counts[mask]) {
                    for (usz dimension = 0; dimension < dimensions; dimension++)
                        if ((mask & (1 << (int)dimension)) != 0) keys[mask][group][dimension] = keys[parent][parent_group][dimension];
                    sums[mask][group] = sums[parent][parent_group]; counts[mask]++;
                } else sums[mask][group] += sums[parent][parent_group];
            }
            for (usz index = 1; index < counts[mask]; index++) {
                usz position = index;
                while (position > 0) {
                    bool less = false;
                    for (usz dimension = 0; dimension < dimensions; dimension++) {
                        if ((mask & (1 << (int)dimension)) == 0) continue;
                        if (keys[mask][position][dimension] < keys[mask][position - 1][dimension]) { less = true; break; }
                        if (keys[mask][position][dimension] > keys[mask][position - 1][dimension]) break;
                    }
                    if (!less) break;
                    for (usz dimension = 0; dimension < dimensions; dimension++) {
                        long temporary = keys[mask][position][dimension]; keys[mask][position][dimension] = keys[mask][position - 1][dimension]; keys[mask][position - 1][dimension] = temporary;
                    }
                    long temporary_sum = sums[mask][position]; sums[mask][position] = sums[mask][position - 1]; sums[mask][position - 1] = temporary_sum;
                    position--;
                }
            }
        }
    }

    long checksum = 0;
    for (int mask = 0; mask <= full; mask++) {
        long view = (long)mask + 1;
        checksum += view * 1000000 + ((long)parents[mask] + 2) * 10000 + (long)counts[mask] * 1000;
        for (usz group = 0; group < counts[mask]; group++) {
            long rank = (long)group + 1;
            checksum += rank * (sums[mask][group] + 1);
            for (usz dimension = 0; dimension < dimensions; dimension++)
                if ((mask & (1 << (int)dimension)) != 0)
                    checksum += rank * (long)(dimension + 1) * (keys[mask][group][dimension] + 1);
        }
    }
    return checksum;
}
