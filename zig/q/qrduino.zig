// Clean-room bounded QR encoder; package README documents source provenance.
// SPDX-License-Identifier: GPL-3.0-or-later
const QR_SIDE: usize = 25;
const QR_CELLS: usize = 625;
const DATA_WORDS: usize = 34;
const ECC_WORDS: usize = 10;
const MAX_MESSAGE: usize = 21;
const PREFIX_BYTES: usize = 22;

fn gfMultiply(left_input: u8, right_input: u8) u8 {
    var left: u16 = left_input;
    var right = right_input;
    var product: u16 = 0;
    while (right != 0) {
        if (right & 1) != 0) product ^= left;
        right >>= 1;
        left <<= 1;
        if ((left & 0x100) != 0) left ^= 0x11d;
    }
    return @intCast(product);
}

fn putBits(target: *[DATA_WORDS]u8, position: *usize, value: u32, width: usize) void {
    var step: usize = 0;
    while (step < width) : (step += 1) {
        const bit = width - 1 - step;
        if (((value >> @intCast(bit)) & 1) != 0)
            target[position.* >> 3] |= @intCast(0x80 >> @intCast(position.* & 7));
        position.* += 1;
    }
}

fn mark(frame: *[QR_CELLS]u8, reserved: *[QR_CELLS]u8, x: i32, y: i32, dark: bool) void {
    if (x < 0 or x >= 25 or y < 0 or y >= 25) return;
    const index: usize = @intCast(y * 25 + x);
    reserved[index] = 1;
    if (dark) frame[index] = 1;
}

fn finder(frame: *[QR_CELLS]u8, reserved: *[QR_CELLS]u8, left: i32, top: i32) void {
    mark(frame, reserved, left + 3, top + 3, true);
    for (0..6) |j| {
        const offset: i32 = @intCast(j);
        mark(frame, reserved, left + offset, top, true);
        mark(frame, reserved, left, top + offset + 1, true);
        mark(frame, reserved, left + 6, top + offset, true);
        mark(frame, reserved, left + offset + 1, top + 6, true);
    }
    for (1..5) |j| {
        const offset: i32 = @intCast(j);
        mark(frame, reserved, left + offset, top + 1, false);
        mark(frame, reserved, left + 1, top + offset + 1, false);
        mark(frame, reserved, left + 5, top + offset, false);
        mark(frame, reserved, left + offset + 1, top + 5, false);
    }
    for (2..4) |j| {
        const offset: i32 = @intCast(j);
        mark(frame, reserved, left + offset, top + 2, true);
        mark(frame, reserved, left + 2, top + offset + 1, true);
        mark(frame, reserved, left + 4, top + offset, true);
        mark(frame, reserved, left + offset + 1, top + 4, true);
    }
}

fn alignment(frame: *[QR_CELLS]u8, reserved: *[QR_CELLS]u8, cx: i32, cy: i32) void {
    mark(frame, reserved, cx, cy, true);
    var offset: i32 = -2;
    while (offset < 2) : (offset += 1) {
        mark(frame, reserved, cx + offset, cy - 2, true);
        mark(frame, reserved, cx - 2, cy + offset + 1, true);
        mark(frame, reserved, cx + 2, cy + offset, true);
        mark(frame, reserved, cx + offset + 1, cy + 2, true);
    }
    var inner: i32 = 0;
    while (inner < 2) : (inner += 1) {
        mark(frame, reserved, cx - 1, cy + inner, false);
        mark(frame, reserved, cx + 1, cy - inner, false);
        mark(frame, reserved, cx - inner, cy - 1, false);
        mark(frame, reserved, cx + inner, cy + 1, false);
    }
}

fn baseFrame(frame: *[QR_CELLS]u8, reserved: *[QR_CELLS]u8) void {
    finder(frame, reserved, 0, 0);
    finder(frame, reserved, 18, 0);
    finder(frame, reserved, 0, 18);
    alignment(frame, reserved, 18, 18);
    mark(frame, reserved, 8, 17, true);
    for (0..9) |x| mark(frame, reserved, @intCast(x), 8, false);
    for (0..8) |x| {
        mark(frame, reserved, @as(i32, @intCast(x)) + 17, 8, false);
        mark(frame, reserved, 8, @intCast(x), false);
    }
    for (0..7) |y| mark(frame, reserved, 8, @as(i32, @intCast(y)) + 18, false);
    for (0..11) |p| {
        const coordinate: i32 = @intCast(p);
        const dark = p % 2 == 0;
        mark(frame, reserved, 8 + coordinate, 6, dark);
        mark(frame, reserved, 6, 8 + coordinate, dark);
    }
    for (0..QR_SIDE) |y| {
        for (0..y + 1) |x| {
            const index = y * QR_SIDE + x;
            if (frame[index] != 0) reserved[index] = 1;
        }
    }
}

fn makeCodewords(message: *const [MAX_MESSAGE]u8, message_length: usize,
                 words: *[DATA_WORDS + ECC_WORDS]u8) void {
    var data: [DATA_WORDS]u8 = .{0} ** DATA_WORDS;
    var position: usize = 0;
    putBits(&data, &position, 4, 4);
    putBits(&data, &position, @intCast(message_length), 8);
    for (0..message_length) |i| putBits(&data, &position, message[i], 8);
    const remaining = DATA_WORDS * 8 - position;
    putBits(&data, &position, 0, @min(remaining, 4));
    while (position & 7 != 0) putBits(&data, &position, 0, 1);
    var pad: u32 = 0xec;
    while (position < DATA_WORDS * 8) {
        putBits(&data, &position, pad, 8);
        pad = if (pad == 0xec) 0x11 else 0xec;
    }
    var generator: [ECC_WORDS + 1]u8 = .{0} ** (ECC_WORDS + 1);
    generator[0] = 1;
    var degree: usize = 0;
    var root: u8 = 1;
    for (0..ECC_WORDS) |_| {
        generator[degree + 1] = 1;
        var j = degree;
        while (j > 0) : (j -= 1) {
            const prior = generator[j - 1];
            const current = generator[j];
            generator[j] = if (current != 0) prior ^ gfMultiply(current, root) else prior;
        }
        generator[0] = gfMultiply(generator[0], root);
        degree += 1;
        root = gfMultiply(root, 2);
    }
    var ecc: [ECC_WORDS]u8 = .{0} ** ECC_WORDS;
    for (0..DATA_WORDS) |i| {
        const factor = data[i] ^ ecc[0];
        for (0..ECC_WORDS - 1) |j|
            ecc[j] = ecc[j + 1] ^ gfMultiply(factor, generator[j + 1]);
        ecc[ECC_WORDS - 1] = gfMultiply(factor, generator[0]);
    }
    @memcpy(words[0..DATA_WORDS], data[0..]);
    @memcpy(words[DATA_WORDS..], ecc[0..]);
}

fn placeData(frame: *[QR_CELLS]u8, reserved: *const [QR_CELLS]u8,
             words: *const [DATA_WORDS + ECC_WORDS]u8) void {
    var x: i32 = 24;
    var y: i32 = 24;
    var moving_up = true;
    var moving_left = true;
    for (0..DATA_WORDS + ECC_WORDS) |i| {
        var byte = words[i];
        for (0..8) |_| {
            if ((byte & 0x80) != 0) frame[@intCast(y * 25 + x)] = 1;
            byte <<= 1;
            while (true) {
                if (moving_left) x -= 1 else {
                    x += 1;
                    if (moving_up) {
                        if (y != 0) y -= 1 else {
                            x -= 2;
                            moving_up = false;
                            if (x == 6) { x -= 1; y = 9; }
                        }
                    } else if (y != 24) y += 1 else {
                        x -= 2;
                        moving_up = true;
                        if (x == 6) { x -= 1; y -= 8; }
                    }
                }
                moving_left = !moving_left;
                if (reserved[@intCast(y * 25 + x)] == 0) break;
            }
        }
    }
}

fn maskedBy(mask: usize, x: usize, y: usize) bool {
    const product = x * y;
    return switch (mask) {
        0 => (x + y) % 2 == 0,
        1 => y % 2 == 0,
        2 => x % 3 == 0,
        3 => (x + y) % 3 == 0,
        4 => (y / 2 + x / 3) % 2 == 0,
        5 => product % 2 + product % 3 == 0,
        6 => (product % 2 + product % 3) % 2 == 0,
        else => ((x + y) % 2 + product % 3) % 2 == 0,
    };
}

fn addFormat(candidate: *[QR_CELLS]u8, mask: usize) void {
    const data: u32 = 8 | @as(u32, @intCast(mask));
    var remainder = data << 10;
    var bit: i32 = 14;
    while (bit >= 10) : (bit -= 1) {
        if ((remainder & (@as(u32, 1) << @intCast(bit))) != 0)
            remainder ^= @as(u32, 0x537) << @intCast(bit - 10);
    }
    const word = ((data << 10) | remainder) ^ @as(u32, 0x5412);
    for (0..6) |i| candidate[i * QR_SIDE + 8] = @intCast((word >> @intCast(i)) & 1);
    candidate[7 * QR_SIDE + 8] = @intCast((word >> 6) & 1);
    candidate[8 * QR_SIDE + 8] = @intCast((word >> 7) & 1);
    candidate[8 * QR_SIDE + 7] = @intCast((word >> 8) & 1);
    for (9..15) |i| candidate[8 * QR_SIDE + 14 - i] = @intCast((word >> @intCast(i)) & 1);
    for (0..8) |i| candidate[8 * QR_SIDE + QR_SIDE - 1 - i] = @intCast((word >> @intCast(i)) & 1);
    for (8..15) |i| candidate[(QR_SIDE - 15 + i) * QR_SIDE + 8] = @intCast((word >> @intCast(i)) & 1);
    candidate[(QR_SIDE - 8) * QR_SIDE + 8] = 1;
}

fn penalty(matrix: *const [QR_CELLS]u8) u32 {
    var score: u32 = 0;
    var dark: u32 = 0;
    for (matrix.*) |value| dark += @as(u32, value);
    for (0..2) |axis| {
        for (0..QR_SIDE) |line| {
            var run: usize = 1;
            for (1..QR_SIDE) |step| {
                const a = if (axis == 1) matrix[step * QR_SIDE + line] else matrix[line * QR_SIDE + step];
                const b = if (axis == 1) matrix[(step - 1) * QR_SIDE + line] else matrix[line * QR_SIDE + step - 1];
                if (a == b) run += 1 else {
                    if (run >= 5) score += @intCast(run - 2);
                    run = 1;
                }
            }
            if (run >= 5) score += @intCast(run - 2);
            for (0..QR_SIDE - 10) |start| {
                var pattern: u16 = 0;
                for (0..11) |j| {
                    const value = if (axis == 1) matrix[(start + j) * QR_SIDE + line] else matrix[line * QR_SIDE + start + j];
                    pattern = (pattern << 1) | value;
                }
                if (pattern == 0x05d or pattern == 0x5d0) score += 40;
            }
        }
    }
    for (0..QR_SIDE - 1) |y| {
        for (0..QR_SIDE - 1) |x| {
            const value = matrix[y * QR_SIDE + x];
            if (value == matrix[y * QR_SIDE + x + 1] and
                value == matrix[(y + 1) * QR_SIDE + x] and
                value == matrix[(y + 1) * QR_SIDE + x + 1]) score += 3;
        }
    }
    const total: u32 = QR_CELLS;
    const scaled = dark * 20;
    const reference = total * 10;
    score += (if (scaled > reference) scaled - reference else reference - scaled) / total * 10;
    return score;
}

fn evaluateMasks(frame: *const [QR_CELLS]u8, reserved: *const [QR_CELLS]u8) usize {
    var best_score: u32 = 0xffffffff;
    var best_mask: usize = 0;
    for (0..8) |mask| {
        var candidate = frame.*;
        for (0..QR_CELLS) |i| {
            if (reserved[i] == 0 and maskedBy(mask, i % QR_SIDE, i / QR_SIDE))
                candidate[i] ^= 1;
        }
        addFormat(&candidate, mask);
        const score = penalty(&candidate);
        if (score < best_score) {
            best_score = score;
            best_mask = mask;
        }
    }
    return best_mask;
}

pub export fn qrduino(input: [*c]const i64, input_length: usize,
                      output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_MESSAGE + 2) return -1;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_MESSAGE)) or input_length != @as(usize, @intCast(input[0])) + 1) return -1;
    const message_length: usize = @intCast(input[0]);
    var message: [MAX_MESSAGE]u8 = .{0} ** MAX_MESSAGE;
    for (0..message_length) |i| {
        if (input[i + 1] < 1 or input[i + 1] > 127) return -1;
        message[i] = @intCast(input[i + 1]);
    }
    if (output == null or output_capacity < PREFIX_BYTES) return -2;

    var words: [DATA_WORDS + ECC_WORDS]u8 = .{0} ** (DATA_WORDS + ECC_WORDS);
    var frame: [QR_CELLS]u8 = .{0} ** QR_CELLS;
    var reserved: [QR_CELLS]u8 = .{0} ** QR_CELLS;
    var staged: [PREFIX_BYTES]u8 = .{0} ** PREFIX_BYTES;
    makeCodewords(&message, message_length, &words);
    baseFrame(&frame, &reserved);
    placeData(&frame, &reserved, &words);
    for (0..6) |y| {
        for (0..QR_SIDE) |x| {
            const byte_index = y * 4 + x / 8;
            if (byte_index < PREFIX_BYTES and frame[y * QR_SIDE + x] != 0)
                staged[byte_index] |= @intCast(0x80 >> @intCast(x & 7));
        }
    }
    _ = evaluateMasks(&frame, &reserved);
    for (0..PREFIX_BYTES) |i| output[i] = staged[i];
    return @intCast(PREFIX_BYTES);
}
