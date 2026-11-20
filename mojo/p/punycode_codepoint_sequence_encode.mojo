from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_POINTS = 32
comptime MAX_WORDS = 34
comptime MAX_OUTPUT = 320

fn adapt_bias(initial_delta: Int64, point_count: Int64, first_time: Bool) -> Int64:
    var delta = initial_delta
    if first_time:
        delta /= 700
    else:
        delta /= 2
    delta += delta / point_count
    var k = Int64(0)
    while delta > 455:
        delta /= 35
        k += 36
    return k + (36 * delta) / (delta + 38)

@export("punycode_codepoint_sequence_encode")
fn punycode_codepoint_sequence_encode(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(1) or length > c_size_t(MAX_WORDS):
        return -1
    let count_word = input[0]
    if count_word < 0 or count_word > MAX_POINTS or length != c_size_t(count_word + 1):
        return -1
    let count = Int(count_word)
    for index in range(count):
        let point = input[index + 1]
        if point < 0 or point > 0x10FFFF or (point >= 0xD800 and point <= 0xDFFF):
            return -1

    var staged = InlineArray[UInt8, MAX_OUTPUT](fill=0)
    var basic_count = 0
    for index in range(count):
        if input[index + 1] < 0x80:
            staged[basic_count] = UInt8(input[index + 1])
            basic_count += 1
    var written = basic_count
    if basic_count != 0:
        staged[written] = UInt8(45)
        written += 1

    var n = Int64(128)
    var delta = Int64(0)
    var bias = Int64(72)
    var handled = basic_count
    while handled < count:
        var minimum = Int64(0x110000)
        for index in range(count):
            if input[index + 1] >= n and input[index + 1] < minimum:
                minimum = input[index + 1]
        delta += (minimum - n) * Int64(handled + 1)
        n = minimum
        for index in range(count):
            let point = input[index + 1]
            if point < n:
                delta += 1
            if point == n:
                var q = delta
                var k = Int64(36)
                while True:
                    var threshold = Int64(1)
                    if k > bias:
                        threshold = k - bias
                    if k >= bias + 26:
                        threshold = 26
                    if q < threshold:
                        if q < 26:
                            staged[written] = UInt8(q + 97)
                        else:
                            staged[written] = UInt8(q + 22)
                        written += 1
                        break
                    let remainder = (q - threshold) % (36 - threshold)
                    let digit = threshold + remainder
                    if digit < 26:
                        staged[written] = UInt8(digit + 97)
                    else:
                        staged[written] = UInt8(digit + 22)
                    written += 1
                    q = (q - threshold) / (36 - threshold)
                    k += 36
                bias = adapt_bias(delta, Int64(handled + 1), handled == basic_count)
                delta = 0
                handled += 1
        delta += 1
        n += 1

    if written > MAX_OUTPUT:
        return -1
    if written != 0:
        if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(written):
            return -2
        for index in range(written):
            output[index] = staged[index]
    return Int64(written)
