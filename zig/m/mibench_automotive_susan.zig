/**********************************************************************\
  SUSAN Version 2l by Stephen Smith
  Oxford Centre for Functional Magnetic Resonance Imaging of the Brain,
  Department of Clinical Neurology, Oxford University, Oxford, UK
  (Previously in Computer Vision and Image Processing Group - now
  Computer Vision and Electro Optics Group - DERA Chertsey, UK)
  Email:    steve@fmrib.ox.ac.uk
  WWW:      http://www.fmrib.ox.ac.uk/~steve
  (C) Crown Copyright (1995-1999), Defence Evaluation and Research Agency,
  Farnborough, Hampshire, GU14 6TD, UK
  DERA WWW site:
  http://www.dera.gov.uk/
  DERA Computer Vision and Electro Optics Group WWW site:
  http://www.dera.gov.uk/imageprocessing/dera/group_home.html
  DERA Computer Vision and Electro Optics Group point of contact:
  Dr. John Savage, jtsavage@dera.gov.uk, +44 1344 633203
  A UK patent has been granted: "Method for digitally processing
  images to determine the position of edges and/or corners therein for
  guidance of unmanned vehicle", UK Patent 2272285. Proprietor:
  Secretary of State for Defence, UK. 15 January 1997

  This code is issued for research purposes only and remains the
  property of the UK Secretary of State for Defence. This code must
  not be passed on without this header information being kept
  intact. This code must not be sold.
\**********************************************************************/
const MIN_SIDE: i64 = 15;
const MAX_SIDE: i64 = 16;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 258;
const MASK_RADIUS: i64 = 7;

fn reflectIndex(index: i64, side: i64) usize {
    if (index < 0) return @intCast(-index - 1);
    if (index >= side) return @intCast(2 * side - index - 1);
    return @intCast(index);
}

fn setupWeights(brightness: *[511]i32, distance: *[225]i32) void {
    for (0..511) |slot| {
        const difference: i64 = @as(i64, @intCast(slot)) - 255;
        var temp: f32 = @as(f32, @floatFromInt(difference)) / 20.0;
        temp *= temp;
        temp = @floatCast(100.0 * @exp(-@as(f64, temp)));
        brightness[slot] = @intFromFloat(temp);
    }
    var index: usize = 0;
    var dy: i64 = -MASK_RADIUS;
    while (dy <= MASK_RADIUS) : (dy += 1) {
        var dx: i64 = -MASK_RADIUS;
        while (dx <= MASK_RADIUS) : (dx += 1) {
            const squared_distance: f32 = @floatFromInt(dx * dx + dy * dy);
            const exponent: f32 = squared_distance / -16.0;
            distance[index] = @intFromFloat(100.0 * @exp(@as(f64, exponent)));
            index += 1;
        }
    }
}

fn medianEight(image: *const [256]u8, side: i64, y: i64, x: i64) u8 {
    var values: [8]u8 = undefined;
    var count: usize = 0;
    var dy: i64 = -1;
    while (dy <= 1) : (dy += 1) {
        var dx: i64 = -1;
        while (dx <= 1) : (dx += 1) {
            if (dx == 0 and dy == 0) continue;
            const sy = reflectIndex(y + dy, side);
            const sx = reflectIndex(x + dx, side);
            values[count] = image[sy * @as(usize, @intCast(side)) + sx];
            count += 1;
        }
    }
    for (0..7) |pass| {
        for (0..7 - pass) |index| {
            if (values[index] > values[index + 1]) {
                const temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
            }
        }
    }
    return @intCast((@as(u16, values[3]) + values[4]) / 2);
}

export fn mibench_automotive_susan(input: ?[*]const i64, input_length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null) return -1;
    if (input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const values = input.?;
    if (values[0] < MIN_SIDE or values[0] > MAX_SIDE) return -1;
    const side: usize = @intCast(values[0]);
    const pixel_count = side * side;
    if (input_length != pixel_count + 1) return -1;
    var image = [_]u8{0} ** 256;
    for (0..pixel_count) |index| {
        const pixel = values[index + 1];
        if (pixel < 0 or pixel > 255) return -1;
        image[index] = @intCast(pixel);
    }
    if (output == null or output_capacity < pixel_count) return -2;
    const output_values = output.?;

    var brightness: [511]i32 = undefined;
    var distance: [225]i32 = undefined;
    setupWeights(&brightness, &distance);
    for (0..side) |y_usize| {
        for (0..side) |x_usize| {
            const y: i64 = @intCast(y_usize);
            const x: i64 = @intCast(x_usize);
            const center: i32 = image[y_usize * side + x_usize];
            var area: i32 = 0;
            var total: i32 = 0;
            var mask_index: usize = 0;
            var dy: i64 = -MASK_RADIUS;
            while (dy <= MASK_RADIUS) : (dy += 1) {
                const sy = reflectIndex(y + dy, @intCast(side));
                var dx: i64 = -MASK_RADIUS;
                while (dx <= MASK_RADIUS) : (dx += 1) {
                    const sx = reflectIndex(x + dx, @intCast(side));
                    const pixel: i32 = image[sy * side + sx];
                    const contribution = distance[mask_index] * brightness[@intCast(center - pixel + 255)];
                    area += contribution;
                    total += contribution * pixel;
                    mask_index += 1;
                }
            }
            const denominator = area - 10000;
            output_values[y_usize * side + x_usize] = if (denominator == 0)
                medianEight(&image, @intCast(side), y, x)
            else
                @intCast(@divTrunc(total - center * 10000, denominator));
        }
    }
    return @intCast(pixel_count);
}

