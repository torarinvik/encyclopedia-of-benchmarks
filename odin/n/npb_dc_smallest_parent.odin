// Bounded clean-room NASA NPB DC smallest-parent profile; see NAS-03-005.
package npb_dc_smallest_parent

import "core:c"

MAX_DIMS :: 5
MAX_ROWS :: 16
MAX_MASKS :: 32

popcount :: proc(value: int) -> int {
    bits := value
    count := 0
    for bits != 0 {
        count += bits & 1
        bits >>= 1
    }
    return count
}

@(export)
npb_dc_smallest_parent :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
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

    keys: [MAX_MASKS][MAX_ROWS][MAX_DIMS]i64 = {}
    sums: [MAX_MASKS][MAX_ROWS]i64 = {}
    counts: [MAX_MASKS]int = {}
    parents: [MAX_MASKS]int = {}
    for mask := 0; mask < MAX_MASKS; mask += 1 do parents[mask] = -2
    full := (1 << dimensions) - 1
    parents[full] = -1
    for row := 0; row < rows; row += 1 {
        group := 0
        for group < counts[full] {
            equal := true
            for dimension := 0; dimension < dimensions; dimension += 1 {
                if (full & (1 << dimension)) != 0 && keys[full][group][dimension] != attributes[row][dimension] do equal = false
            }
            if equal do break
            group += 1
        }
        if group == counts[full] {
            for dimension := 0; dimension < dimensions; dimension += 1 do keys[full][group][dimension] = attributes[row][dimension]
            sums[full][group] = measures[row]
            counts[full] += 1
        } else sums[full][group] += measures[row]
    }
    for index := 1; index < counts[full]; index += 1 {
        position := index
        for position > 0 {
            less := false
            for dimension := 0; dimension < dimensions; dimension += 1 {
                if keys[full][position][dimension] < keys[full][position-1][dimension] { less = true; break }
                if keys[full][position][dimension] > keys[full][position-1][dimension] { break }
            }
            if !less do break
            temporary := keys[full][position]
            keys[full][position] = keys[full][position-1]
            keys[full][position-1] = temporary
            temporary_sum := sums[full][position]
            sums[full][position] = sums[full][position-1]
            sums[full][position-1] = temporary_sum
            position -= 1
        }
    }

    for wanted := dimensions-1; wanted >= 0; wanted -= 1 {
        for mask := 0; mask <= full; mask += 1 {
            if popcount(mask) != wanted do continue
            parent := -1
            best := MAX_ROWS + 1
            for dimension := 0; dimension < dimensions; dimension += 1 {
                bit := 1 << dimension
                if (mask & bit) != 0 do continue
                candidate := mask | bit
                if parent < 0 || counts[candidate] < best {
                    parent = candidate
                    best = counts[candidate]
                }
            }
            if parent < 0 do return -1
            parents[mask] = parent
            for parent_group := 0; parent_group < counts[parent]; parent_group += 1 {
                group := 0
                for group < counts[mask] {
                    equal := true
                    for dimension := 0; dimension < dimensions; dimension += 1 {
                        if (mask & (1 << dimension)) != 0 && keys[mask][group][dimension] != keys[parent][parent_group][dimension] do equal = false
                    }
                    if equal do break
                    group += 1
                }
                if group == counts[mask] {
                    for dimension := 0; dimension < dimensions; dimension += 1 {
                        if (mask & (1 << dimension)) != 0 do keys[mask][group][dimension] = keys[parent][parent_group][dimension]
                    }
                    sums[mask][group] = sums[parent][parent_group]
                    counts[mask] += 1
                } else sums[mask][group] += sums[parent][parent_group]
            }
            for index := 1; index < counts[mask]; index += 1 {
                position := index
                for position > 0 {
                    less := false
                    for dimension := 0; dimension < dimensions; dimension += 1 {
                        if (mask & (1 << dimension)) == 0 do continue
                        if keys[mask][position][dimension] < keys[mask][position-1][dimension] { less = true; break }
                        if keys[mask][position][dimension] > keys[mask][position-1][dimension] { break }
                    }
                    if !less do break
                    temporary := keys[mask][position]
                    keys[mask][position] = keys[mask][position-1]
                    keys[mask][position-1] = temporary
                    temporary_sum := sums[mask][position]
                    sums[mask][position] = sums[mask][position-1]
                    sums[mask][position-1] = temporary_sum
                    position -= 1
                }
            }
        }
    }

    checksum := i64(0)
    for mask := 0; mask <= full; mask += 1 {
        view := i64(mask + 1)
        checksum += view * 1000000 + (i64(parents[mask]) + 2) * 10000 + i64(counts[mask]) * 1000
        for group := 0; group < counts[mask]; group += 1 {
            rank := i64(group + 1)
            checksum += rank * (sums[mask][group] + 1)
            for dimension := 0; dimension < dimensions; dimension += 1 {
                if (mask & (1 << dimension)) != 0 {
                    checksum += rank * i64(dimension+1) * (keys[mask][group][dimension] + 1)
                }
            }
        }
    }
    return checksum
}
