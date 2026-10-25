// Clean-room bounded QR encoder; package README documents source provenance.
// SPDX-License-Identifier: GPL-3.0-or-later
package qrduino

import "core:c"

QR_SIDE :: 25
QR_CELLS :: 625
DATA_WORDS :: 34
ECC_WORDS :: 10
MAX_MESSAGE :: 21
PREFIX_BYTES :: 22

gf_multiply :: proc(left_input, right_input: u8) -> u8 {
    left := u16(left_input)
    right := right_input
    product: u16 = 0
    for right != 0 {
        if right & 1 != 0 do product ^= left
        right >>= 1
        left <<= 1
        if left & 0x100 != 0 do left ^= 0x11d
    }
    return u8(product)
}

put_bits :: proc(target: [^]u8, position: ^int, value: u32, width: int) {
    for bit := width; bit > 0; bit -= 1 {
        if (value >> u32(bit - 1)) & 1 != 0 {
            target[position^ / 8] |= u8(0x80 >> u32(position^ & 7))
        }
        position^ += 1
    }
}

mark :: proc(frame, reserved: [^]u8, x, y: int, dark: bool) {
    if x < 0 || x >= QR_SIDE || y < 0 || y >= QR_SIDE do return
    index := y * QR_SIDE + x
    reserved[index] = 1
    if dark do frame[index] = 1
}

finder :: proc(frame, reserved: [^]u8, left, top: int) {
    mark(frame, reserved, left + 3, top + 3, true)
    for j := 0; j < 6; j += 1 {
        mark(frame, reserved, left + j, top, true)
        mark(frame, reserved, left, top + j + 1, true)
        mark(frame, reserved, left + 6, top + j, true)
        mark(frame, reserved, left + j + 1, top + 6, true)
    }
    for j := 1; j < 5; j += 1 {
        mark(frame, reserved, left + j, top + 1, false)
        mark(frame, reserved, left + 1, top + j + 1, false)
        mark(frame, reserved, left + 5, top + j, false)
        mark(frame, reserved, left + j + 1, top + 5, false)
    }
    for j := 2; j < 4; j += 1 {
        mark(frame, reserved, left + j, top + 2, true)
        mark(frame, reserved, left + 2, top + j + 1, true)
        mark(frame, reserved, left + 4, top + j, true)
        mark(frame, reserved, left + j + 1, top + 4, true)
    }
}

alignment :: proc(frame, reserved: [^]u8, cx, cy: int) {
    mark(frame, reserved, cx, cy, true)
    for j := -2; j < 2; j += 1 {
        mark(frame, reserved, cx + j, cy - 2, true)
        mark(frame, reserved, cx - 2, cy + j + 1, true)
        mark(frame, reserved, cx + 2, cy + j, true)
        mark(frame, reserved, cx + j + 1, cy + 2, true)
    }
    for j := 0; j < 2; j += 1 {
        mark(frame, reserved, cx - 1, cy + j, false)
        mark(frame, reserved, cx + 1, cy - j, false)
        mark(frame, reserved, cx - j, cy - 1, false)
        mark(frame, reserved, cx + j, cy + 1, false)
    }
}

base_frame :: proc(frame, reserved: [^]u8) {
    finder(frame, reserved, 0, 0)
    finder(frame, reserved, QR_SIDE - 7, 0)
    finder(frame, reserved, 0, QR_SIDE - 7)
    alignment(frame, reserved, 18, 18)
    mark(frame, reserved, 8, QR_SIDE - 8, true)
    for x := 0; x < 9; x += 1 do mark(frame, reserved, x, 8, false)
    for x := 0; x < 8; x += 1 {
        mark(frame, reserved, x + QR_SIDE - 8, 8, false)
        mark(frame, reserved, 8, x, false)
    }
    for y := 0; y < 7; y += 1 do mark(frame, reserved, 8, y + QR_SIDE - 7, false)
    for p := 0; p < QR_SIDE - 14; p += 1 {
        dark := p & 1 == 0
        mark(frame, reserved, 8 + p, 6, dark)
        mark(frame, reserved, 6, 8 + p, dark)
    }
    for y := 0; y < QR_SIDE; y += 1 {
        for x := 0; x <= y; x += 1 {
            index := y * QR_SIDE + x
            if frame[index] != 0 do reserved[index] = 1
        }
    }
}

make_codewords :: proc(message: [^]u8, length: int, words: [^]u8) {
    data: [DATA_WORDS]u8 = {}
    position := 0
    put_bits(&data[0], &position, 4, 4)
    put_bits(&data[0], &position, u32(length), 8)
    for i := 0; i < length; i += 1 do put_bits(&data[0], &position, u32(message[i]), 8)
    remaining := DATA_WORDS * 8 - position
    put_bits(&data[0], &position, 0, min(remaining, 4))
    for position & 7 != 0 do put_bits(&data[0], &position, 0, 1)
    pad: u32 = 0xec
    for position < DATA_WORDS * 8 {
        put_bits(&data[0], &position, pad, 8)
        pad = if pad == 0xec then 0x11 else 0xec
    }
    generator: [ECC_WORDS + 1]u8 = {}
    generator[0] = 1
    degree := 0
    root: u8 = 1
    for _ in 0 .. ECC_WORDS {
        generator[degree + 1] = 1
        for j := degree; j > 0; j -= 1 {
            prior := generator[j - 1]
            current := generator[j]
            generator[j] = if current != 0 then prior ^ gf_multiply(current, root) else prior
        }
        generator[0] = gf_multiply(generator[0], root)
        degree += 1
        root = gf_multiply(root, 2)
    }
    ecc: [ECC_WORDS]u8 = {}
    for i := 0; i < DATA_WORDS; i += 1 {
        factor := data[i] ^ ecc[0]
        for j := 0; j < ECC_WORDS - 1; j += 1
            ecc[j] = ecc[j + 1] ^ gf_multiply(factor, generator[j + 1])
        ecc[ECC_WORDS - 1] = gf_multiply(factor, generator[0])
    }
    for i := 0; i < DATA_WORDS; i += 1 do words[i] = data[i]
    for i := 0; i < ECC_WORDS; i += 1 do words[DATA_WORDS + i] = ecc[i]
}

place_data :: proc(frame, reserved: [^]u8, words: [^]u8) {
    x, y := QR_SIDE - 1, QR_SIDE - 1
    moving_up, moving_left := true, true
    for i := 0; i < DATA_WORDS + ECC_WORDS; i += 1 {
        byte := words[i]
        for _ in 0 .. 8 {
            if byte & 0x80 != 0 do frame[y * QR_SIDE + x] = 1
            byte <<= 1
            for {
                if moving_left do x -= 1
                else {
                    x += 1
                    if moving_up {
                        if y != 0 do y -= 1
                        else {
                            x -= 2
                            moving_up = false
                            if x == 6 { x -= 1; y = 9 }
                        }
                    } else if y != QR_SIDE - 1 do y += 1
                    else {
                        x -= 2
                        moving_up = true
                        if x == 6 { x -= 1; y -= 8 }
                    }
                }
                moving_left = !moving_left
                if reserved[y * QR_SIDE + x] == 0 do break
            }
        }
    }
}

masked_by :: proc(mask, x, y: int) -> bool {
    product := x * y
    switch mask {
    case 0: return (x + y) % 2 == 0
    case 1: return y % 2 == 0
    case 2: return x % 3 == 0
    case 3: return (x + y) % 3 == 0
    case 4: return (y / 2 + x / 3) % 2 == 0
    case 5: return product % 2 + product % 3 == 0
    case 6: return (product % 2 + product % 3) % 2 == 0
    case: return ((x + y) % 2 + product % 3) % 2 == 0
    }
    return false
}

add_format :: proc(candidate: [^]u8, mask: int) {
    data := u32(8 | mask)
    remainder := data << 10
    for bit := 14; bit >= 10; bit -= 1 {
        if remainder & (1 << u32(bit)) != 0 do remainder ^= 0x537 << u32(bit - 10)
    }
    word := ((data << 10) | remainder) ^ 0x5412
    for bit := 0; bit < 6; bit += 1 do candidate[bit * QR_SIDE + 8] = u8((word >> u32(bit)) & 1)
    candidate[7 * QR_SIDE + 8] = u8((word >> 6) & 1)
    candidate[8 * QR_SIDE + 8] = u8((word >> 7) & 1)
    candidate[8 * QR_SIDE + 7] = u8((word >> 8) & 1)
    for bit := 9; bit < 15; bit += 1 do candidate[8 * QR_SIDE + 14 - bit] = u8((word >> u32(bit)) & 1)
    for bit := 0; bit < 8; bit += 1 do candidate[8 * QR_SIDE + QR_SIDE - 1 - bit] = u8((word >> u32(bit)) & 1)
    for bit := 8; bit < 15; bit += 1 do candidate[(QR_SIDE - 15 + bit) * QR_SIDE + 8] = u8((word >> u32(bit)) & 1)
    candidate[(QR_SIDE - 8) * QR_SIDE + 8] = 1
}

penalty :: proc(matrix: [^]u8) -> u32 {
    score, dark: u32 = 0, 0
    for i := 0; i < QR_CELLS; i += 1 do dark += u32(matrix[i])
    for axis := 0; axis < 2; axis += 1 {
        for line := 0; line < QR_SIDE; line += 1 {
            run := 1
            for step := 1; step < QR_SIDE; step += 1 {
                a := if axis == 1 then matrix[step * QR_SIDE + line] else matrix[line * QR_SIDE + step]
                b := if axis == 1 then matrix[(step - 1) * QR_SIDE + line] else matrix[line * QR_SIDE + step - 1]
                if a == b do run += 1
                else { if run >= 5 do score += u32(run - 2); run = 1 }
            }
            if run >= 5 do score += u32(run - 2)
            for start := 0; start + 11 <= QR_SIDE; start += 1 {
                pattern: u32 = 0
                for j := 0; j < 11; j += 1 {
                    value := if axis == 1 then matrix[(start + j) * QR_SIDE + line] else matrix[line * QR_SIDE + start + j]
                    pattern = (pattern << 1) | u32(value)
                }
                if pattern == 0x05d || pattern == 0x5d0 do score += 40
            }
        }
    }
    for y := 0; y + 1 < QR_SIDE; y += 1 {
        for x := 0; x + 1 < QR_SIDE; x += 1 {
            value := matrix[y * QR_SIDE + x]
            if value == matrix[y * QR_SIDE + x + 1] &&
                value == matrix[(y + 1) * QR_SIDE + x] &&
                value == matrix[(y + 1) * QR_SIDE + x + 1] do score += 3
        }
    }
    total: u32 = QR_CELLS
    balance := if dark * 20 > total * 10 then dark * 20 - total * 10 else total * 10 - dark * 20
    return score + balance / total * 10
}

evaluate_masks :: proc(frame, reserved: [^]u8) -> int {
    best_score: u32 = 0xffffffff
    best_mask := 0
    for mask := 0; mask < 8; mask += 1 {
        candidate: [QR_CELLS]u8 = {}
        for i := 0; i < QR_CELLS; i += 1 {
            candidate[i] = frame[i]
            if reserved[i] == 0 && masked_by(mask, i % QR_SIDE, i / QR_SIDE) do candidate[i] ^= 1
        }
        add_format(&candidate[0], mask)
        score := penalty(&candidate[0])
        if score < best_score { best_score = score; best_mask = mask }
    }
    return best_mask
}

@(export)
qrduino :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
    capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_MESSAGE + 2 do return -1
    if input[0] < 1 || input[0] > MAX_MESSAGE || length != c.size_t(input[0] + 1) do return -1
    message_length := int(input[0])
    message: [MAX_MESSAGE]u8 = {}
    for i := 0; i < message_length; i += 1 {
        if input[i + 1] < 1 || input[i + 1] > 127 do return -1
        message[i] = u8(input[i + 1])
    }
    if output == nil || capacity < PREFIX_BYTES do return -2
    words: [DATA_WORDS + ECC_WORDS]u8 = {}
    frame: [QR_CELLS]u8 = {}
    reserved: [QR_CELLS]u8 = {}
    staged: [PREFIX_BYTES]u8 = {}
    make_codewords(&message[0], message_length, &words[0])
    base_frame(&frame[0], &reserved[0])
    place_data(&frame[0], &reserved[0], &words[0])
    for y := 0; y < 6; y += 1 {
        for x := 0; x < QR_SIDE; x += 1 {
            byte_index := y * 4 + x / 8
            if byte_index < PREFIX_BYTES && frame[y * QR_SIDE + x] != 0 do staged[byte_index] |= u8(0x80 >> u32(x & 7))
        }
    }
    _ = evaluate_masks(&frame[0], &reserved[0])
    for i := 0; i < PREFIX_BYTES; i += 1 do output[i] = staged[i]
    return PREFIX_BYTES
}
