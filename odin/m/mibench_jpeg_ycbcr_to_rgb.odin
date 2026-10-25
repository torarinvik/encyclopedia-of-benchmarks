package mibench_jpeg_ycbcr_to_rgb
import "core:c"

arshift16 :: proc(x: i64) -> i64 { if x >= 0 { return x / 65536 }; return -((-x + 65535) / 65536) }
clamp8 :: proc(x: i64) -> u8 { return u8(max(0, min(255, x))) }

@(export, link_name="mibench_jpeg_ycbcr_to_rgb")
mibench_jpeg_ycbcr_to_rgb :: proc "c"(v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
    if v == nil || n < 4 || n > 49 do return -1
    if v[0] < 1 || v[0] > 16 || n != c.size_t(1 + 3 * v[0]) do return -1
    for i: c.size_t = 1; i < n; i += 1 { if v[i] < 0 || v[i] > 255 do return -1 }
    staged: [48]u8
    p: c.size_t = 0
    for i: c.size_t = 1; i < n; i += 3 {
        y := v[i]; cb := v[i+1]-128; cr := v[i+2]-128
        staged[p]=clamp8(y+arshift16(91881*cr+32768)); p+=1
        staged[p]=clamp8(y+arshift16(-22554*cb+32768-46802*cr)); p+=1
        staged[p]=clamp8(y+arshift16(116130*cb+32768)); p+=1
    }
    if out == nil || cap < p do return -2
    for i: c.size_t = 0; i < p; i += 1 { out[i]=staged[i] }
    return i64(p)
}
