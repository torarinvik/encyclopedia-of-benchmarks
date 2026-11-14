# Independent version 2-L QR encoder draft; see package README and LICENSE.txt.
# SPDX-License-Identifier: GPL-3.0-or-later
# Draft only; compilation and output have not been verified.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn qr_gf_product(left: Int, right: Int) -> Int:
    var x = left
    var y = right
    var result = 0
    while y > 0:
        if (y & 1) != 0: result ^= x
        x <<= 1
        if (x & 256) != 0: x ^= 285
        y >>= 1
    return result

fn qr_append(mut words: InlineArray[Int, 44], mut position: Int,
             value: Int, width: Int):
    for index in range(width):
        let bit = (value >> (width - index - 1)) & 1
        words[position // 8] |= bit << (7 - position % 8)
        position += 1

# The message has already been checked as 1..21 nonzero ASCII bytes.
fn qr_codewords(message: InlineArray[Int, 21], length: Int,
                mut words: InlineArray[Int, 44]):
    var position = 0
    qr_append(words, position, 4, 4)
    qr_append(words, position, length, 8)
    for i in range(length): qr_append(words, position, message[i], 8)
    let remaining = 272 - position
    var terminator = 4
    if remaining < 4: terminator = remaining
    qr_append(words, position, 0, terminator)
    while position % 8 != 0: qr_append(words, position, 0, 1)
    var pad = 236
    while position < 272:
        qr_append(words, position, pad, 8)
        if pad == 236: pad = 17
        else: pad = 236

    # Coefficients in ascending degree order for product(x + alpha^k).
    var generator = InlineArray[Int, 11](fill=0)
    generator[0] = 1
    var root = 1
    for degree in range(10):
        generator[degree + 1] = 1
        for reverse in range(degree):
            let j = degree - reverse
            generator[j] = generator[j - 1] ^ qr_gf_product(generator[j], root)
        generator[0] = qr_gf_product(generator[0], root)
        root = qr_gf_product(root, 2)
    var parity = InlineArray[Int, 10](fill=0)
    for i in range(34):
        let factor = words[i] ^ parity[0]
        for j in range(9): parity[j] = parity[j + 1] ^ qr_gf_product(factor, generator[j + 1])
        parity[9] = qr_gf_product(factor, generator[0])
    for i in range(10): words[34 + i] = parity[i]

fn qr_mark(mut frame: InlineArray[Int, 625], mut reserved: InlineArray[Int, 625],
           x: Int, y: Int, dark: Bool):
    if x < 0 or x >= 25 or y < 0 or y >= 25: return
    reserved[25 * y + x] = 1
    if dark: frame[25 * y + x] = 1

fn qr_finder(mut frame: InlineArray[Int, 625], mut reserved: InlineArray[Int, 625],
              left: Int, top: Int):
    for y in range(7):
        for x in range(7):
            let outer = x == 0 or x == 6 or y == 0 or y == 6
            let core = x >= 2 and x <= 4 and y >= 2 and y <= 4
            qr_mark(frame, reserved, left + x, top + y, outer or core)

fn qr_frame(mut frame: InlineArray[Int, 625], mut reserved: InlineArray[Int, 625]):
    qr_finder(frame, reserved, 0, 0)
    qr_finder(frame, reserved, 18, 0)
    qr_finder(frame, reserved, 0, 18)
    for y in range(-2, 3):
        for x in range(-2, 3):
            let ring = x == -2 or x == 2 or y == -2 or y == 2
            qr_mark(frame, reserved, 18 + x, 18 + y, ring or (x == 0 and y == 0))
    qr_mark(frame, reserved, 8, 17, True)
    for x in range(9): qr_mark(frame, reserved, x, 8, False)
    for i in range(8):
        qr_mark(frame, reserved, 17 + i, 8, False)
        qr_mark(frame, reserved, 8, i, False)
    for y in range(7): qr_mark(frame, reserved, 8, 18 + y, False)
    for i in range(11):
        qr_mark(frame, reserved, 8 + i, 6, (i & 1) == 0)
        qr_mark(frame, reserved, 6, 8 + i, (i & 1) == 0)

fn qr_place(mut frame: InlineArray[Int, 625], reserved: InlineArray[Int, 625],
            words: InlineArray[Int, 44]):
    var x = 24
    var y = 24
    var up = True
    var left = True
    for index in range(352):
        let bit = (words[index // 8] >> (7 - index % 8)) & 1
        if bit != 0: frame[25 * y + x] = 1
        while True:
            if left:
                x -= 1
            else:
                x += 1
                if up:
                    if y != 0: y -= 1
                    else:
                        x -= 2
                        up = False
                        if x == 6:
                            x -= 1
                            y = 9
                else:
                    if y != 24: y += 1
                    else:
                        x -= 2
                        up = True
                        if x == 6:
                            x -= 1
                            y -= 8
            left = not left
            if reserved[25 * y + x] == 0: break

fn qr_mask(mask: Int, x: Int, y: Int) -> Bool:
    let product = x * y
    if mask == 0: return (x + y) % 2 == 0
    if mask == 1: return y % 2 == 0
    if mask == 2: return x % 3 == 0
    if mask == 3: return (x + y) % 3 == 0
    if mask == 4: return (y // 2 + x // 3) % 2 == 0
    if mask == 5: return product % 2 + product % 3 == 0
    if mask == 6: return (product % 2 + product % 3) % 2 == 0
    return ((x + y) % 2 + product % 3) % 2 == 0

fn qr_format(mut candidate: InlineArray[Int, 625], mask: Int):
    let data = 8 | mask
    var remainder = data << 10
    for i in range(5):
        let bit = 14 - i
        if (remainder & (1 << bit)) != 0: remainder ^= 1335 << (bit - 10)
    let word = ((data << 10) | remainder) ^ 21522
    for bit in range(6): candidate[25 * bit + 8] = (word >> bit) & 1
    candidate[7 * 25 + 8] = (word >> 6) & 1
    candidate[8 * 25 + 8] = (word >> 7) & 1
    candidate[8 * 25 + 7] = (word >> 8) & 1
    for bit in range(9, 15): candidate[8 * 25 + 14 - bit] = (word >> bit) & 1
    for bit in range(8): candidate[8 * 25 + 24 - bit] = (word >> bit) & 1
    for bit in range(8, 15): candidate[(10 + bit) * 25 + 8] = (word >> bit) & 1
    candidate[17 * 25 + 8] = 1

fn qr_line_cell(frame: InlineArray[Int, 625], axis: Int, line: Int, offset: Int) -> Int:
    if axis == 0: return frame[25 * line + offset]
    return frame[25 * offset + line]

fn qr_penalty(frame: InlineArray[Int, 625]) -> Int:
    var score = 0
    var dark = 0
    for i in range(625): dark += frame[i]
    for axis in range(2):
        for line in range(25):
            var run = 1
            for i in range(1, 25):
                if qr_line_cell(frame, axis, line, i) == qr_line_cell(frame, axis, line, i - 1):
                    run += 1
                else:
                    if run >= 5: score += run - 2
                    run = 1
            if run >= 5: score += run - 2
            for start in range(15):
                var pattern = 0
                for i in range(11): pattern = (pattern << 1) | qr_line_cell(frame, axis, line, start + i)
                if pattern == 93 or pattern == 1488: score += 40
    for y in range(24):
        for x in range(24):
            let index = 25 * y + x
            let value = frame[index]
            if value == frame[index + 1] and value == frame[index + 25] and value == frame[index + 26]:
                score += 3
    var imbalance = dark * 20 - 6250
    if imbalance < 0: imbalance = -imbalance
    return score + (imbalance // 625) * 10

fn qr_best_mask(frame: InlineArray[Int, 625], reserved: InlineArray[Int, 625]) -> Int:
    var best = 0
    var best_score = 2147483647
    for mask in range(8):
        var candidate = InlineArray[Int, 625](fill=0)
        for i in range(625):
            candidate[i] = frame[i]
            if reserved[i] == 0 and qr_mask(mask, i % 25, i // 25): candidate[i] ^= 1
        qr_format(candidate, mask)
        let score = qr_penalty(candidate)
        if score < best_score:
            best_score = score
            best = mask
    return best

@export("qrduino")
fn qrduino(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 23: return -1
    if input[0] < 1 or input[0] > 21 or length != c_size_t(input[0] + 1): return -1
    let count = Int(input[0])
    var message = InlineArray[Int, 21](fill=0)
    for i in range(count):
        if input[i + 1] < 1 or input[i + 1] > 127: return -1
        message[i] = Int(input[i + 1])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 22: return -2
    var words = InlineArray[Int, 44](fill=0)
    var frame = InlineArray[Int, 625](fill=0)
    var reserved = InlineArray[Int, 625](fill=0)
    qr_codewords(message, count, words)
    qr_frame(frame, reserved)
    qr_place(frame, reserved, words)
    var encoded = InlineArray[UInt8, 22](fill=0)
    for y in range(6):
        for x in range(25):
            let index = 4 * y + x // 8
            if index < 22 and frame[25 * y + x] != 0: encoded[index] |= UInt8(128 >> (x % 8))
    let selected = qr_best_mask(frame, reserved)
    _ = selected
    for i in range(22): output[i] = encoded[i]
    return 22
