const OUTPUT_BYTES: usize = 3;
const MAX_COMPONENT_SCALED: i64 = 255_000_000;

fn sectionRemainderTwo(section: f64) f64 {
    if (section < 2.0) return section;
    if (section < 4.0) return section - 2.0;
    if (section < 6.0) return section - 4.0;
    return section - 6.0;
}

fn roundChannel(channel: f64) u8 {
    return @intFromFloat(255.0 * channel + 0.5);
}

export fn hsv_to_rgb_conversion(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    if (input[0] < 0 or input[0] > 360_000 or input[1] < 0 or input[1] > MAX_COMPONENT_SCALED or
        input[2] < 0 or input[2] > MAX_COMPONENT_SCALED) return -1;
    if (output == null or capacity < OUTPUT_BYTES) return -2;

    const hue = @as(f64, @floatFromInt(input[0])) / 1000.0;
    const saturation = @as(f64, @floatFromInt(input[1])) / 255_000_000.0;
    const value = @as(f64, @floatFromInt(input[2])) / 255_000_000.0;
    const chroma = value * saturation;
    const hue_section = hue / 60.0;
    const remainder = sectionRemainderTwo(hue_section);
    const second = chroma * (1.0 - @abs(remainder - 1.0));
    const matched = value - chroma;
    var red: f64 = 0.0;
    var green: f64 = 0.0;
    var blue: f64 = 0.0;
    if (hue_section >= 0.0 and hue_section <= 1.0) {
        red=chroma+matched; green=second+matched; blue=matched;
    } else if (hue_section > 1.0 and hue_section <= 2.0) {
        red=second+matched; green=chroma+matched; blue=matched;
    } else if (hue_section > 2.0 and hue_section <= 3.0) {
        red=matched; green=chroma+matched; blue=second+matched;
    } else if (hue_section > 3.0 and hue_section <= 4.0) {
        red=matched; green=second+matched; blue=chroma+matched;
    } else if (hue_section > 4.0 and hue_section <= 5.0) {
        red=second+matched; green=matched; blue=chroma+matched;
    } else {
        red=chroma+matched; green=matched; blue=second+matched;
    }
    output[0] = roundChannel(red);
    output[1] = roundChannel(green);
    output[2] = roundChannel(blue);
    return OUTPUT_BYTES;
}
