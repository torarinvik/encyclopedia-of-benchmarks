// Independently written bounded IJG h2v2 adaptation; see package README/LICENSE.
package cbench_consumer_jpeg_h2v2_fancy_upsample

import "core:c"

MAX_WIDTH :: 16
MAX_HEIGHT :: 8
MAX_OUTPUT :: 512

@(export)
cbench_consumer_jpeg_h2v2_fancy_upsample :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 5 || length > 131 do return -1
    if input[0] < 3 || input[0] > MAX_WIDTH || input[1] < 1 || input[1] > MAX_HEIGHT do return -1
    width := int(input[0])
    height := int(input[1])
    pixels := width * height
    if length != c.size_t(2 + pixels) do return -1
    for i := 0; i < pixels; i += 1 {
        if input[i+2] < 0 || input[i+2] > 255 do return -1
    }
    output_size := 4 * pixels
    if output == nil || capacity < c.size_t(output_size) do return -2
    staged: [MAX_OUTPUT]u8 = {}
    p := 0
    for y := 0; y < height; y += 1 {
        for v := 0; v < 2; v += 1 {
            far_y := y
            if v == 0 { if y > 0 do far_y = y - 1 } else { if y + 1 < height do far_y = y + 1 }
            sums: [MAX_WIDTH]int = {}
            for x := 0; x < width; x += 1 {
                sums[x] = 3 * int(input[2+y*width+x]) + int(input[2+far_y*width+x])
            }
            staged[p] = u8((sums[0]*4+8) >> 4); p += 1
            staged[p] = u8((sums[0]*3+sums[1]+7) >> 4); p += 1
            for x := 1; x < width-1; x += 1 {
                staged[p] = u8((sums[x]*3+sums[x-1]+8) >> 4); p += 1
                staged[p] = u8((sums[x]*3+sums[x+1]+7) >> 4); p += 1
            }
            staged[p] = u8((sums[width-1]*3+sums[width-2]+8) >> 4); p += 1
            staged[p] = u8((sums[width-1]*4+7) >> 4); p += 1
        }
    }
    for i := 0; i < output_size; i += 1 { output[i] = staged[i] }
    return i64(output_size)
}
