/* NAS Parallel Benchmarks 3.3 DC source notice:
 * Permission to use, copy, distribute and modify this software for any purpose
 * with or without fee is hereby granted. We request, however, that all derived
 * work reference the NAS Parallel Benchmarks 3.3. This software is provided
 * "as is" without express or implied warranty.
 *
 * Clean-room bounded adaptation: packed input and ordered scalar checksum
 * replace generated files and the original memory management harness.
 */
package npb_serial_dc

import "core:c"

MAX_DIMS :: 5
MAX_ROWS :: 16

@(export)
npb_serial_dc :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > 98 do return -1
    if input[0] < 1 || input[0] > MAX_DIMS || input[1] < 1 || input[1] > MAX_ROWS do return -1
    dimensions := int(input[0])
    rows := int(input[1])
    if int(length) != 2 + rows * (dimensions + 1) do return -1

    attributes: [MAX_ROWS][MAX_DIMS]i64 = {}
    measures: [MAX_ROWS]i64 = {}
    offset := 2
    for row := 0; row < rows; row += 1 {
        for dimension := 0; dimension < dimensions; dimension += 1 {
            value := input[offset]
            offset += 1
            if value < 0 || value > 7 do return -1
            attributes[row][dimension] = value
        }
        measures[row] = input[offset]
        offset += 1
        if measures[row] < 0 || measures[row] > 1000 do return -1
    }

    checksum := i64(0)
    for mask := 1; mask < (1 << dimensions); mask += 1 {
        keys: [MAX_ROWS][MAX_DIMS]i64 = {}
        sums: [MAX_ROWS]i64 = {}
        group_count := 0
        for row := 0; row < rows; row += 1 {
            group := 0
            for group < group_count {
                equal := true
                for dimension := 0; dimension < dimensions; dimension += 1 {
                    if (mask & (1 << dimension)) != 0 && keys[group][dimension] != attributes[row][dimension] do equal = false
                }
                if equal do break
                group += 1
            }
            if group == group_count {
                for dimension := 0; dimension < dimensions; dimension += 1 {
                    if (mask & (1 << dimension)) != 0 do keys[group][dimension] = attributes[row][dimension]
                }
                sums[group] = measures[row]
                group_count += 1
            } else sums[group] += measures[row]
        }
        for index := 1; index < group_count; index += 1 {
            position := index
            for position > 0 {
                comparison := 0
                for dimension := 0; dimension < dimensions; dimension += 1 {
                    if (mask & (1 << dimension)) == 0 do continue
                    if keys[position][dimension] < keys[position-1][dimension] { comparison = -1; break }
                    if keys[position][dimension] > keys[position-1][dimension] { comparison = 1; break }
                }
                if comparison >= 0 do break
                temporary := keys[position]
                keys[position] = keys[position-1]
                keys[position-1] = temporary
                temporary_sum := sums[position]
                sums[position] = sums[position-1]
                sums[position-1] = temporary_sum
                position -= 1
            }
        }
        view := i64(mask)
        checksum += view * 1009 + i64(group_count) * 9176
        for group := 0; group < group_count; group += 1 {
            checksum += (view + 1) * i64(group+1) * (sums[group] + 13)
            for dimension := 0; dimension < dimensions; dimension += 1 {
                if (mask & (1 << dimension)) != 0 {
                    checksum += i64(dimension+1) * (keys[group][dimension]+1) * i64(group+3) * (view+5)
                }
            }
        }
    }
    return checksum
}
