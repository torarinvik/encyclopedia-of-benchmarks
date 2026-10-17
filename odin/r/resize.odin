package resize

import "core:c"

MAX_INPUT_LENGTH :: c.size_t(3077)
MAX_OUTPUT_BYTES :: c.size_t(3072)

@(export, link_name="resize")
resize :: proc "c" (input: [^]i64, length: c.size_t,
                     output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
    src_width, src_height, dst_width, dst_height := input[0], input[1], input[2], input[3]
    if src_width < 1 || src_width > 32 || src_height < 1 || src_height > 32 ||
        dst_width < 1 || dst_width > 32 || dst_height < 1 || dst_height > 32 do return -1

    src_w, src_h := usize(src_width), usize(src_height)
    dst_w, dst_h := usize(dst_width), usize(dst_height)
    expected_length := c.size_t(4 + 3 * src_w * src_h)
    if length != expected_length do return -1
    for i: usize = 4; i < usize(expected_length); i += 1 {
        if input[i] < 0 || input[i] > 255 do return -1
    }

    needed := c.size_t(3 * dst_w * dst_h)
    if needed > MAX_OUTPUT_BYTES do return -1
    if output == nil || capacity < needed do return -2

    ratio_x := f64(src_width) / f64(dst_width)
    ratio_y := f64(src_height) / f64(dst_height)
    out: usize = 0
    for y: usize = 0; y < dst_h; y += 1 {
        src_y := usize(ratio_y * f64(y))
        for x: usize = 0; x < dst_w; x += 1 {
            src_x := usize(ratio_x * f64(x))
            src := 4 + 3 * (src_y * src_w + src_x)
            output[out] = u8(input[src])
            output[out + 1] = u8(input[src + 1])
            output[out + 2] = u8(input[src + 2])
            out += 3
        }
    }
    return i64(needed)
}
