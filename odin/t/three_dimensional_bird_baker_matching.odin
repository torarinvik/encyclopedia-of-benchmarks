package three_dimensional_bird_baker_matching
import "core:c"

MAX_DIM :: 5
MAX_PAT_DIM :: 4
MAX_INPUT :: 196
MAX_MATCHES :: 125

put_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

same_rows :: proc(plane: [^]i64, left, right, width: int) -> bool {
    for column := 0; column < width; column += 1 {
        if plane[left*width+column] != plane[right*width+column] do return false
    }
    return true
}

@(export)
three_dimensional_bird_baker_matching :: proc "c" (
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 7 || length > MAX_INPUT do return -1
    r0, c0, d0 := input[0], input[1], input[2]
    pr0, pc0, pd0 := input[3], input[4], input[5]
    if r0 < 1 || r0 > 5 || c0 < 1 || c0 > 5 || d0 < 1 || d0 > 5
        || pr0 < 1 || pr0 > 4 || pc0 < 1 || pc0 > 4 || pd0 < 1 || pd0 > 4
        || pr0 > r0 || pc0 > c0 || pd0 > d0 do return -1
    rows, columns, depths := int(r0), int(c0), int(d0)
    p_rows, p_columns, p_depths := int(pr0), int(pc0), int(pd0)
    text_size := rows * columns * depths
    pattern_size := p_rows * p_columns * p_depths
    if int(length) != 6 + text_size + pattern_size do return -1
    text: [MAX_DIM * MAX_DIM * MAX_DIM]i64
    pattern: [MAX_PAT_DIM * MAX_PAT_DIM * MAX_PAT_DIM]i64
    for i := 0; i < text_size; i += 1 {
        text[i] = input[6+i]
        if text[i] < 0 || text[i] > 3 do return -1
    }
    for i := 0; i < pattern_size; i += 1 {
        pattern[i] = input[6+text_size+i]
        if pattern[i] < 0 || pattern[i] > 3 do return -1
    }

    plane_ids: [MAX_PAT_DIM]int
    unique_planes: [MAX_PAT_DIM][MAX_PAT_DIM * MAX_PAT_DIM]i64
    plane_area := p_rows * p_columns
    unique_count := 0
    for pz := 0; pz < p_depths; pz += 1 {
        found := unique_count
        for candidate := 0; candidate < unique_count; candidate += 1 {
            equal := true
            for i := 0; i < plane_area; i += 1 {
                if unique_planes[candidate][i] != pattern[pz*plane_area+i] do equal = false
            }
            if equal { found = candidate; break }
        }
        if found == unique_count {
            for i := 0; i < plane_area; i += 1 { unique_planes[unique_count][i] = pattern[pz*plane_area+i] }
            unique_count += 1
        }
        plane_ids[pz] = found
    }

    row_starts := rows - p_rows + 1
    column_starts := columns - p_columns + 1
    labels: [MAX_DIM * MAX_DIM * MAX_DIM]i64
    for i := 0; i < MAX_DIM*MAX_DIM*MAX_DIM; i += 1 { labels[i] = -1 }
    for z := 0; z < depths; z += 1 {
        for unique := 0; unique < unique_count; unique += 1 {
            marks: [MAX_DIM * MAX_DIM * MAX_PAT_DIM]bool
            prefix: [MAX_PAT_DIM]int
            for i := 1; i < p_rows; i += 1 {
                matched := prefix[i-1]
                for matched > 0 && !same_rows(&unique_planes[unique][0], i, matched, p_columns) {
                    matched = prefix[matched-1]
                }
                if same_rows(&unique_planes[unique][0], i, matched, p_columns) do matched += 1
                prefix[i] = matched
            }
            for row := 0; row < rows; row += 1 {
                for column := 0; column < column_starts; column += 1 {
                    for p_row := 0; p_row < p_rows; p_row += 1 {
                        equal := true
                        for p_column := 0; p_column < p_columns; p_column += 1 {
                            if text[(z*rows+row)*columns+column+p_column] != unique_planes[unique][p_row*p_columns+p_column] do equal = false
                        }
                        marks[(row*MAX_DIM+column)*MAX_PAT_DIM+p_row] = equal
                    }
                }
            }
            for column := 0; column < column_starts; column += 1 {
                matched := 0
                for row := 0; row < rows; row += 1 {
                    for matched > 0 && !marks[(row*MAX_DIM+column)*MAX_PAT_DIM+matched] {
                        matched = prefix[matched-1]
                    }
                    if marks[(row*MAX_DIM+column)*MAX_PAT_DIM+matched] do matched += 1
                    if matched == p_rows {
                        labels[(z*MAX_DIM+row+1-p_rows)*MAX_DIM+column] = i64(unique)
                        matched = prefix[matched-1]
                    }
                }
            }
        }
    }

    depth_prefix: [MAX_PAT_DIM]int
    for i := 1; i < p_depths; i += 1 {
        matched := depth_prefix[i-1]
        for matched > 0 && plane_ids[i] != plane_ids[matched] { matched = depth_prefix[matched-1] }
        if plane_ids[i] == plane_ids[matched] do matched += 1
        depth_prefix[i] = matched
    }
    matches: [MAX_MATCHES * 3]i64
    count := 0
    for row := 0; row < row_starts; row += 1 {
        for column := 0; column < column_starts; column += 1 {
            matched := 0
            for z := 0; z < depths; z += 1 {
                token := labels[(z*MAX_DIM+row)*MAX_DIM+column]
                for matched > 0 && token != i64(plane_ids[matched]) { matched = depth_prefix[matched-1] }
                if token == i64(plane_ids[matched]) do matched += 1
                if matched == p_depths {
                    matches[count*3] = i64(row)
                    matches[count*3+1] = i64(column)
                    matches[count*3+2] = i64(z+1-p_depths)
                    count += 1
                    matched = depth_prefix[matched-1]
                }
            }
        }
    }
    bytes := 8 * (1 + 3*count)
    if output == nil || capacity < c.size_t(bytes) do return -2
    put_le(output, 0, i64(count))
    for i := 0; i < 3*count; i += 1 { put_le(output, 8*(i+1), matches[i]) }
    return i64(bytes)
}
