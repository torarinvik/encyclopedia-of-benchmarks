// Rodinia DWT2D (Jiri Matela, Martin Jirman); complete notices in
// benchmarks/r/rodinia_dwt2d/LICENSE.txt. Independent scalar 5/3 lifting port.
module rodinia_dwt2d

fn div_trunc(numerator i64, denominator i64) i64 {
    if numerator < 0 { return -((-numerator) / denominator) }
    return numerator / denominator
}

fn transform_line(line [16]i64, n int) [16]i64 {
    mut result := [16]i64{}
    mut detail := [8]i64{}
    half := n / 2
    for j in 0 .. half {
        even := line[2 * j]
        right := if j + 1 < half { line[2 * j + 2] } else { even }
        detail[j] = line[2 * j + 1] - div_trunc(even + right, 2)
    }
    result[0] = line[0] + div_trunc(detail[0] + detail[0] + 2, 4)
    for j in 1 .. half { result[j] = line[2 * j] + div_trunc(detail[j - 1] + detail[j] + 2, 4) }
    for j in 0 .. half { result[half + j] = detail[j] }
    return result
}

@[export: 'rodinia_dwt2d']
pub fn rodinia_dwt2d(values &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if values == nil || length < 3 || length > 259 { return -1 }
        wi, hi, li := values[0], values[1], values[2]
        if wi < 2 || wi > 16 || hi < 2 || hi > 16 || li < 1 || li > 3 { return -1 }
        factor := i64(1) << u32(li)
        if wi < factor || hi < factor || wi % factor != 0 || hi % factor != 0 { return -1 }
        width, height := int(wi), int(hi)
        cells := width * height
        if length != usize(3 + cells) { return -1 }
        for i in 0 .. cells { if values[3 + i] < 0 || values[3 + i] > 255 { return -1 } }
        output_bytes := cells * 4
        if output == nil || capacity < usize(output_bytes) { return -2 }

        mut plane := [256]i64{}
        mut vertical := [256]i64{}
        mut next := [256]i64{}
        mut ordered := [256]i64{}
        for i in 0 .. cells { plane[i] = values[3 + i] - 128 }
        mut active_width, mut active_height := width, height
        for _ in 0 .. int(li) {
            for x in 0 .. active_width {
                mut line := [16]i64{}
                for y in 0 .. active_height { line[y] = plane[y * width + x] }
                transformed := transform_line(line, active_height)
                for y in 0 .. active_height { vertical[y * width + x] = transformed[y] }
            }
            for y in 0 .. active_height {
                mut line := [16]i64{}
                for x in 0 .. active_width { line[x] = vertical[y * width + x] }
                transformed := transform_line(line, active_width)
                for x in 0 .. active_width { next[y * width + x] = transformed[x] }
            }
            for y in 0 .. active_height {
                for x in 0 .. active_width { plane[y * width + x] = next[y * width + x] }
            }
            active_width /= 2
            active_height /= 2
        }
        mut output_index := 0
        for stage in 0 .. int(li) {
            level := int(li) - 1 - stage
            stage_width := width >> level
            stage_height := height >> level
            half_width, half_height := stage_width / 2, stage_height / 2
            if level == int(li) - 1 {
                for y in 0 .. half_height {
                    for x in 0 .. half_width { ordered[output_index] = plane[y * width + x]; output_index++ }
                }
            }
            for y in 0 .. half_height {
                for x in half_width .. stage_width { ordered[output_index] = plane[y * width + x]; output_index++ }
            }
            for y in half_height .. stage_height {
                for x in 0 .. half_width { ordered[output_index] = plane[y * width + x]; output_index++ }
            }
            for y in half_height .. stage_height {
                for x in half_width .. stage_width { ordered[output_index] = plane[y * width + x]; output_index++ }
            }
        }
        for i in 0 .. cells {
            bits := u32(i32(ordered[i]))
            for byte in 0 .. 4 { output[4 * i + byte] = u8((bits >> u32(8 * byte)) & 255) }
        }
        return i64(output_bytes)
    }
}
