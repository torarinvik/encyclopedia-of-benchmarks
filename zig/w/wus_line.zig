const std = @import("std");

const COORDINATE_LIMIT: i64 = 64;
const MAX_PIXELS: usize = 258;

const Endpoint = struct {
    x_pixel: i64,
    y_pixel: i64,
    y_end: f64,
    x_gap: f64,
};

fn fractionPart(value: f64) f64 { return value - @floor(value); }
fn reverseFractionPart(value: f64) f64 { return 1.0 - fractionPart(value); }

fn addPixel(pixel_x: *[MAX_PIXELS]i64, pixel_y: *[MAX_PIXELS]i64,
    intensities: *[MAX_PIXELS]f64, count: *usize,
    x_value: i64, y_value: i64, intensity: f64, steep: bool) void {
    const x = if (steep) y_value else x_value;
    const y = if (steep) x_value else y_value;
    pixel_x[count.*] = x;
    pixel_y[count.*] = y;
    intensities[count.*] = @max(0.0, @min(1.0, intensity));
    count.* += 1;
}

fn addEndpoint(pixel_x: *[MAX_PIXELS]i64, pixel_y: *[MAX_PIXELS]i64,
    intensities: *[MAX_PIXELS]f64, count: *usize,
    endpoint: Endpoint, steep: bool) void {
    const fractional_y = fractionPart(endpoint.y_end);
    const complement = reverseFractionPart(endpoint.y_end);
    addPixel(pixel_x, pixel_y, intensities, count, endpoint.x_pixel,
        endpoint.y_pixel, complement * endpoint.x_gap, steep);
    addPixel(pixel_x, pixel_y, intensities, count, endpoint.x_pixel,
        endpoint.y_pixel + 1, fractional_y * endpoint.x_gap, steep);
}

fn writeI32Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn writeF64Le(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn wus_line(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 4) return -1;
    for (0..4) |index| {
        if (values[index] < -COORDINATE_LIMIT or values[index] > COORDINATE_LIMIT) return -1;
    }

    var x0 = values[0];
    var y0 = values[1];
    var x1 = values[2];
    var y1 = values[3];
    const steep = @abs(y1 - y0) > @abs(x1 - x0);
    if (steep) { std.mem.swap(i64, &x0, &y0); std.mem.swap(i64, &x1, &y1); }
    if (x0 > x1) { std.mem.swap(i64, &x0, &x1); std.mem.swap(i64, &y0, &y1); }

    const delta_x = @as(f64, @floatFromInt(x1)) - @as(f64, @floatFromInt(x0));
    const delta_y = @as(f64, @floatFromInt(y1)) - @as(f64, @floatFromInt(y0));
    const gradient = if (delta_x == 0.0) 1.0 else delta_y / delta_x;
    const x0_float = @as(f64, @floatFromInt(x0));
    const x1_float = @as(f64, @floatFromInt(x1));
    const y0_float = @as(f64, @floatFromInt(y0));
    const y1_float = @as(f64, @floatFromInt(y1));
    const first_x_end = @floor(x0_float + 0.5);
    const first_y_end = y0_float + gradient * (first_x_end - x0_float);
    const first = Endpoint{
        .x_pixel = @intFromFloat(first_x_end),
        .y_pixel = @intFromFloat(@floor(first_y_end)),
        .y_end = first_y_end,
        .x_gap = reverseFractionPart(x0_float + 0.5),
    };
    const second_x_end = @floor(x1_float + 0.5);
    const second_y_end = y1_float + gradient * (second_x_end - x1_float);
    const second = Endpoint{
        .x_pixel = @intFromFloat(second_x_end),
        .y_pixel = @intFromFloat(@floor(second_y_end)),
        .y_end = second_y_end,
        .x_gap = fractionPart(x1_float + 0.5),
    };

    var pixel_x: [MAX_PIXELS]i64 = @splat(0);
    var pixel_y: [MAX_PIXELS]i64 = @splat(0);
    var intensities: [MAX_PIXELS]f64 = @splat(0.0);
    var pixel_count: usize = 0;
    addEndpoint(&pixel_x, &pixel_y, &intensities, &pixel_count, first, steep);
    addEndpoint(&pixel_x, &pixel_y, &intensities, &pixel_count, second, steep);

    var intersection_y = first.y_end + gradient;
    var x = first.x_pixel + 1;
    while (x < second.x_pixel) : (x += 1) {
        const y_floor: i64 = @intFromFloat(@floor(intersection_y));
        const fractional = fractionPart(intersection_y);
        const complement = reverseFractionPart(intersection_y);
        addPixel(&pixel_x, &pixel_y, &intensities, &pixel_count, x, y_floor, complement, steep);
        addPixel(&pixel_x, &pixel_y, &intensities, &pixel_count, x, y_floor + 1, fractional, steep);
        intersection_y += gradient;
    }

    const required = pixel_count * 16;
    if (output == null or output_capacity < required) return -2;
    for (0..pixel_count) |index| {
        const offset = index * 16;
        writeI32Le(output, offset, pixel_x[index]);
        writeI32Le(output, offset + 4, pixel_y[index]);
        writeF64Le(output, offset + 8, intensities[index]);
    }
    return @intCast(required);
}
