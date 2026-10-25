// Clean-room bounded QR encoder; package README documents source provenance.
// SPDX-License-Identifier: GPL-3.0-or-later
const QR_SIDE: usize = 25;
const QR_CELLS: usize = 625;
const DATA_WORDS: usize = 34;
const ECC_WORDS: usize = 10;
const MAX_MESSAGE: usize = 21;
const PREFIX_BYTES: usize = 22;

fn gf_multiply(left: u8, mut right: u8) -> u8 {
    let mut product = 0u16;
    let mut factor = left as u16;
    while right != 0 {
        if right & 1 != 0 { product ^= factor; }
        right >>= 1;
        factor <<= 1;
        if factor & 0x100 != 0 { factor ^= 0x11d; }
    }
    product as u8
}

fn put_bits(target: &mut [u8], position: &mut usize, value: u32, width: usize) {
    for bit in (0..width).rev() {
        if (value >> bit) & 1 != 0 {
            target[*position >> 3] |= 0x80 >> (*position & 7);
        }
        *position += 1;
    }
}

fn mark(frame: &mut [u8; QR_CELLS], reserved: &mut [u8; QR_CELLS], x: i32, y: i32, dark: bool) {
    if x < 0 || x >= QR_SIDE as i32 || y < 0 || y >= QR_SIDE as i32 { return; }
    let index = y as usize * QR_SIDE + x as usize;
    reserved[index] = 1;
    if dark { frame[index] = 1; }
}

fn finder(frame: &mut [u8; QR_CELLS], reserved: &mut [u8; QR_CELLS], left: i32, top: i32) {
    mark(frame, reserved, left + 3, top + 3, true);
    for j in 0..6 {
        mark(frame, reserved, left + j, top, true);
        mark(frame, reserved, left, top + j + 1, true);
        mark(frame, reserved, left + 6, top + j, true);
        mark(frame, reserved, left + j + 1, top + 6, true);
    }
    for j in 1..5 {
        mark(frame, reserved, left + j, top + 1, false);
        mark(frame, reserved, left + 1, top + j + 1, false);
        mark(frame, reserved, left + 5, top + j, false);
        mark(frame, reserved, left + j + 1, top + 5, false);
    }
    for j in 2..4 {
        mark(frame, reserved, left + j, top + 2, true);
        mark(frame, reserved, left + 2, top + j + 1, true);
        mark(frame, reserved, left + 4, top + j, true);
        mark(frame, reserved, left + j + 1, top + 4, true);
    }
}

fn alignment(frame: &mut [u8; QR_CELLS], reserved: &mut [u8; QR_CELLS], cx: i32, cy: i32) {
    mark(frame, reserved, cx, cy, true);
    for j in -2..2 {
        mark(frame, reserved, cx + j, cy - 2, true);
        mark(frame, reserved, cx - 2, cy + j + 1, true);
        mark(frame, reserved, cx + 2, cy + j, true);
        mark(frame, reserved, cx + j + 1, cy + 2, true);
    }
    for j in 0..2 {
        mark(frame, reserved, cx - 1, cy + j, false);
        mark(frame, reserved, cx + 1, cy - j, false);
        mark(frame, reserved, cx - j, cy - 1, false);
        mark(frame, reserved, cx + j, cy + 1, false);
    }
}

fn base_frame(frame: &mut [u8; QR_CELLS], reserved: &mut [u8; QR_CELLS]) {
    finder(frame, reserved, 0, 0);
    finder(frame, reserved, QR_SIDE as i32 - 7, 0);
    finder(frame, reserved, 0, QR_SIDE as i32 - 7);
    alignment(frame, reserved, 18, 18);
    mark(frame, reserved, 8, QR_SIDE as i32 - 8, true);
    for x in 0..9 { mark(frame, reserved, x, 8, false); }
    for x in 0..8 {
        mark(frame, reserved, x + QR_SIDE as i32 - 8, 8, false);
        mark(frame, reserved, 8, x, false);
    }
    for y in 0..7 { mark(frame, reserved, 8, y + QR_SIDE as i32 - 7, false); }
    for p in 0..QR_SIDE - 14 {
        let dark = p & 1 == 0;
        mark(frame, reserved, 8 + p as i32, 6, dark);
        mark(frame, reserved, 6, 8 + p as i32, dark);
    }
    for y in 0..QR_SIDE {
        for x in 0..=y {
            let index = y * QR_SIDE + x;
            if frame[index] != 0 { reserved[index] = 1; }
        }
    }
}

fn make_codewords(message: &[u8], words: &mut [u8; DATA_WORDS + ECC_WORDS]) {
    let mut position = 0usize;
    {
        put_bits(&mut words[..DATA_WORDS], &mut position, 4, 4);
        put_bits(&mut words[..DATA_WORDS], &mut position, message.len() as u32, 8);
        for byte in message { put_bits(&mut words[..DATA_WORDS], &mut position, *byte as u32, 8); }
        let remaining = DATA_WORDS * 8 - position;
        put_bits(&mut words[..DATA_WORDS], &mut position, 0, remaining.min(4));
        while position & 7 != 0 { put_bits(&mut words[..DATA_WORDS], &mut position, 0, 1); }
        let mut pad = 0xec;
        while position < DATA_WORDS * 8 {
            put_bits(&mut words[..DATA_WORDS], &mut position, pad, 8);
            pad = if pad == 0xec { 0x11 } else { 0xec };
        }
    }
    let mut generator = [0u8; ECC_WORDS + 1];
    generator[0] = 1;
    let mut degree = 0usize;
    let mut root = 1u8;
    for _ in 0..ECC_WORDS {
        generator[degree + 1] = 1;
        for j in (1..=degree).rev() {
            let prior = generator[j - 1];
            let current = generator[j];
            generator[j] = if current != 0 { prior ^ gf_multiply(current, root) } else { prior };
        }
        generator[0] = gf_multiply(generator[0], root);
        degree += 1;
        root = gf_multiply(root, 2);
    }
    let mut ecc = [0u8; ECC_WORDS];
    for i in 0..DATA_WORDS {
        let factor = words[i] ^ ecc[0];
        for j in 0..ECC_WORDS - 1 {
            ecc[j] = ecc[j + 1] ^ gf_multiply(factor, generator[j + 1]);
        }
        ecc[ECC_WORDS - 1] = gf_multiply(factor, generator[0]);
    }
    words[DATA_WORDS..].copy_from_slice(&ecc);
}

fn place_data(frame: &mut [u8; QR_CELLS], reserved: &[u8; QR_CELLS],
              words: &[u8; DATA_WORDS + ECC_WORDS]) {
    let mut x = QR_SIDE as i32 - 1;
    let mut y = QR_SIDE as i32 - 1;
    let mut moving_up = true;
    let mut moving_left = true;
    for byte_value in words {
        let mut byte = *byte_value;
        for _ in 0..8 {
            if byte & 0x80 != 0 { frame[y as usize * QR_SIDE + x as usize] = 1; }
            byte <<= 1;
            loop {
                if moving_left { x -= 1; }
                else {
                    x += 1;
                    if moving_up {
                        if y != 0 { y -= 1; }
                        else {
                            x -= 2;
                            moving_up = false;
                            if x == 6 { x -= 1; y = 9; }
                        }
                    } else if y != QR_SIDE as i32 - 1 { y += 1; }
                    else {
                        x -= 2;
                        moving_up = true;
                        if x == 6 { x -= 1; y -= 8; }
                    }
                }
                moving_left = !moving_left;
                if reserved[y as usize * QR_SIDE + x as usize] == 0 { break; }
            }
        }
    }
}

fn masked_by(mask: usize, x: usize, y: usize) -> bool {
    let product = x * y;
    match mask {
        0 => (x + y) % 2 == 0,
        1 => y % 2 == 0,
        2 => x % 3 == 0,
        3 => (x + y) % 3 == 0,
        4 => (y / 2 + x / 3) % 2 == 0,
        5 => product % 2 + product % 3 == 0,
        6 => (product % 2 + product % 3) % 2 == 0,
        _ => ((x + y) % 2 + product % 3) % 2 == 0,
    }
}

fn add_format(candidate: &mut [u8; QR_CELLS], mask: usize) {
    let data = 8u32 | mask as u32;
    let mut remainder = data << 10;
    for bit in (10..=14).rev() {
        if remainder & (1 << bit) != 0 { remainder ^= 0x537 << (bit - 10); }
    }
    let word = ((data << 10) | remainder) ^ 0x5412;
    for bit in 0..6 { candidate[bit * QR_SIDE + 8] = ((word >> bit) & 1) as u8; }
    candidate[7 * QR_SIDE + 8] = ((word >> 6) & 1) as u8;
    candidate[8 * QR_SIDE + 8] = ((word >> 7) & 1) as u8;
    candidate[8 * QR_SIDE + 7] = ((word >> 8) & 1) as u8;
    for bit in 9..15 { candidate[8 * QR_SIDE + 14 - bit] = ((word >> bit) & 1) as u8; }
    for bit in 0..8 { candidate[8 * QR_SIDE + QR_SIDE - 1 - bit] = ((word >> bit) & 1) as u8; }
    for bit in 8..15 { candidate[(QR_SIDE - 15 + bit) * QR_SIDE + 8] = ((word >> bit) & 1) as u8; }
    candidate[(QR_SIDE - 8) * QR_SIDE + 8] = 1;
}

fn penalty(matrix: &[u8; QR_CELLS]) -> u32 {
    let mut score = 0u32;
    let dark = matrix.iter().map(|v| *v as u32).sum::<u32>();
    for axis in 0..2 {
        for line in 0..QR_SIDE {
            let at = |step: usize| if axis == 1 { matrix[step * QR_SIDE + line] }
                else { matrix[line * QR_SIDE + step] };
            let mut run = 1usize;
            for step in 1..QR_SIDE {
                if at(step) == at(step - 1) { run += 1; }
                else { if run >= 5 { score += (run - 2) as u32; } run = 1; }
            }
            if run >= 5 { score += (run - 2) as u32; }
            for start in 0..QR_SIDE - 10 {
                let mut pattern = 0u16;
                for j in 0..11 { pattern = (pattern << 1) | at(start + j) as u16; }
                if pattern == 0x05d || pattern == 0x5d0 { score += 40; }
            }
        }
    }
    for y in 0..QR_SIDE - 1 {
        for x in 0..QR_SIDE - 1 {
            let value = matrix[y * QR_SIDE + x];
            if value == matrix[y * QR_SIDE + x + 1]
                && value == matrix[(y + 1) * QR_SIDE + x]
                && value == matrix[(y + 1) * QR_SIDE + x + 1] { score += 3; }
        }
    }
    let total = QR_CELLS as u32;
    let balance = if dark * 20 > total * 10 { dark * 20 - total * 10 } else { total * 10 - dark * 20 };
    score + balance / total * 10
}

fn evaluate_masks(frame: &[u8; QR_CELLS], reserved: &[u8; QR_CELLS]) -> usize {
    let mut best_score = u32::MAX;
    let mut best_mask = 0usize;
    for mask in 0..8 {
        let mut candidate = *frame;
        for i in 0..QR_CELLS {
            if reserved[i] == 0 && masked_by(mask, i % QR_SIDE, i / QR_SIDE) {
                candidate[i] ^= 1;
            }
        }
        add_format(&mut candidate, mask);
        let score = penalty(&candidate);
        if score < best_score { best_score = score; best_mask = mask; }
    }
    best_mask
}

#[no_mangle]
pub unsafe extern "C" fn qrduino(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_MESSAGE + 2 { return -1; }
    if *input < 1 || *input > MAX_MESSAGE as i64 || length != *input as usize + 1 { return -1; }
    let message_length = *input as usize;
    let mut message = [0u8; MAX_MESSAGE];
    for i in 0..message_length {
        let value = *input.add(i + 1);
        if !(1..=127).contains(&value) { return -1; }
        message[i] = value as u8;
    }
    if output.is_null() || capacity < PREFIX_BYTES { return -2; }

    let mut words = [0u8; DATA_WORDS + ECC_WORDS];
    let mut frame = [0u8; QR_CELLS];
    let mut reserved = [0u8; QR_CELLS];
    let mut staged = [0u8; PREFIX_BYTES];
    make_codewords(&message[..message_length], &mut words);
    base_frame(&mut frame, &mut reserved);
    place_data(&mut frame, &reserved, &words);
    for y in 0..6 {
        for x in 0..QR_SIDE {
            let byte_index = y * 4 + x / 8;
            if byte_index < PREFIX_BYTES && frame[y * QR_SIDE + x] != 0 {
                staged[byte_index] |= 0x80 >> (x & 7);
            }
        }
    }
    let _selected = evaluate_masks(&frame, &reserved);
    for i in 0..PREFIX_BYTES { output.add(i).write(staged[i]); }
    PREFIX_BYTES as i64
}
