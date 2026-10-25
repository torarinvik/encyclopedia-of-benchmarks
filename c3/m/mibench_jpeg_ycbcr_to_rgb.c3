module mibench_jpeg_ycbcr_to_rgb;

fn long arshift16(long x) { return x >= 0 ? x / 65536 : -((-x + 65535) / 65536); }
fn u8 clamp8(long x) { return (u8)(x < 0 ? 0 : (x > 255 ? 255 : x)); }

fn long mibench_jpeg_ycbcr_to_rgb(long* v, usz n, u8* out, usz cap)
    @export("mibench_jpeg_ycbcr_to_rgb")
{
    if (v == null || n < 4 || n > 49) return -1;
    if (v[0] < 1 || v[0] > 16 || n != 1 + 3 * (usz)v[0]) return -1;
    for (usz i = 1; i < n; i++) if (v[i] < 0 || v[i] > 255) return -1;
    u8[48] staged;
    usz p = 0;
    for (usz i = 1; i < n; i += 3) {
        long y=v[i], cb=v[i+1]-128, cr=v[i+2]-128;
        staged[p++]=clamp8(y+arshift16(91881*cr+32768));
        staged[p++]=clamp8(y+arshift16(-22554*cb+32768-46802*cr));
        staged[p++]=clamp8(y+arshift16(116130*cb+32768));
    }
    if (out == null || cap < p) return -2;
    for (usz i = 0; i < p; i++) out[i]=staged[i];
    return (long)p;
}
