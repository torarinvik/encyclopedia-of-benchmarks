// Rodinia DWT2D (Jiri Matela, Martin Jirman); complete notices in
// benchmarks/r/rodinia_dwt2d/LICENSE.txt. Independent scalar 5/3 lifting port.
package rodinia_dwt2d
import "core:c"

MAX_SIDE :: 16
MAX_CELLS :: MAX_SIDE * MAX_SIDE
MAX_INPUT :: 3 + MAX_CELLS

div_trunc :: proc "contextless" (numerator, denominator: i64) -> i64 {
    if numerator < 0 do return -((-numerator)/denominator)
    return numerator/denominator
}

transform_line :: proc "contextless" (line: [16]i64, n: int) -> [16]i64 {
    result: [16]i64
    detail: [8]i64
    half := n / 2
    for j := 0; j < half; j += 1 {
        even := line[2*j]
        right := if j+1 < half do line[2*j+2] else do even
        detail[j] = line[2*j+1] - div_trunc(even+right, 2)
    }
    result[0] = line[0] + div_trunc(detail[0]+detail[0]+2, 4)
    for j := 1; j < half; j += 1 { result[j] = line[2*j] + div_trunc(detail[j-1]+detail[j]+2, 4) }
    for j := 0; j < half; j += 1 { result[half+j] = detail[j] }
    return result
}

put_i32_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
    bits := transmute(u32)i32(value)
    for byte: usize = 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
rodinia_dwt2d :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length < 3 || length > c.size_t(MAX_INPUT) do return -1
    wi, hi, li := values[0], values[1], values[2]
    if wi < 2 || wi > 16 || hi < 2 || hi > 16 || li < 1 || li > 3 do return -1
    factor := i64(1) << u32(li)
    if wi < factor || hi < factor || wi % factor != 0 || hi % factor != 0 do return -1
    width, height := usize(wi), usize(hi)
    cells := width * height
    if length != c.size_t(3+cells) do return -1
    for i: usize = 0; i < cells; i += 1 { if values[3+i] < 0 || values[3+i] > 255 do return -1 }
    output_bytes := cells * 4
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    plane: [MAX_CELLS]i64 = {}
    vertical: [MAX_CELLS]i64 = {}
    next: [MAX_CELLS]i64 = {}
    ordered: [MAX_CELLS]i64 = {}
    for i: usize = 0; i < cells; i += 1 { plane[i] = values[3+i]-128 }
    active_width, active_height := width, height
    for level := 0; level < int(li); level += 1 {
        for x: usize = 0; x < active_width; x += 1 {
            line: [16]i64
            for y: usize = 0; y < active_height; y += 1 { line[y] = plane[y*width+x] }
            transformed := transform_line(line, int(active_height))
            for y: usize = 0; y < active_height; y += 1 { vertical[y*width+x] = transformed[y] }
        }
        for y: usize = 0; y < active_height; y += 1 {
            line: [16]i64
            for x: usize = 0; x < active_width; x += 1 { line[x] = vertical[y*width+x] }
            transformed := transform_line(line, int(active_width))
            for x: usize = 0; x < active_width; x += 1 { next[y*width+x] = transformed[x] }
        }
        for y: usize = 0; y < active_height; y += 1 {
            for x: usize = 0; x < active_width; x += 1 { plane[y*width+x] = next[y*width+x] }
        }
        active_width /= 2
        active_height /= 2
    }
    output_index: usize = 0
    for stage := int(li)-1; stage >= 0; stage -= 1 {
        stage_width, stage_height := width >> stage, height >> stage
        half_width, half_height := stage_width/2, stage_height/2
        if stage == int(li)-1 {
            for y: usize = 0; y < half_height; y += 1 {
                for x: usize = 0; x < half_width; x += 1 { ordered[output_index] = plane[y*width+x]; output_index += 1 }
            }
        }
        for y: usize = 0; y < half_height; y += 1 {
            for x := half_width; x < stage_width; x += 1 { ordered[output_index] = plane[y*width+x]; output_index += 1 }
        }
        for y := half_height; y < stage_height; y += 1 {
            for x: usize = 0; x < half_width; x += 1 { ordered[output_index] = plane[y*width+x]; output_index += 1 }
        }
        for y := half_height; y < stage_height; y += 1 {
            for x := half_width; x < stage_width; x += 1 { ordered[output_index] = plane[y*width+x]; output_index += 1 }
        }
    }
    for i: usize = 0; i < cells; i += 1 { put_i32_le(output, 4*i, ordered[i]) }
    return i64(output_bytes)
}
