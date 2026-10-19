from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn words_scale_value(system: Int64, index: Int64) -> UInt64:
    if system == 0:
        if index == 0: return 1000000000000000
        if index == 1: return 1000000000000
        if index == 2: return 1000000000
        if index == 3: return 1000000
        if index == 4: return 1000
        return 100
    if system == 1:
        if index == 0: return 1000000000000000
        if index == 1: return 1000000000
        if index == 2: return 1000000
        if index == 3: return 1000
        return 100
    if index == 0: return 100000000000000
    if index == 1: return 1000000000000
    if index == 2: return 10000000
    if index == 3: return 100000
    if index == 4: return 1000
    return 100

fn words_scale_name(system: Int64, index: Int64) -> String:
    if system == 0:
        if index == 0: return "quadrillion"
        if index == 1: return "trillion"
        if index == 2: return "billion"
        if index == 3: return "million"
        if index == 4: return "thousand"
        return "hundred"
    if system == 1:
        if index == 0: return "billiard"
        if index == 1: return "milliard"
        if index == 2: return "million"
        if index == 3: return "thousand"
        return "hundred"
    if index == 0: return "crore crore"
    if index == 1: return "lakh crore"
    if index == 2: return "crore"
    if index == 3: return "lakh"
    if index == 4: return "thousand"
    return "hundred"

fn words_append_raw(output: UnsafePointer[UInt8, MutAnyOrigin], at_arg: Int64, text: String, emit: Bool) -> Int64:
    var at = at_arg
    for byte in text.as_bytes():
        if emit: output[at] = byte
        at += 1
    return at

fn words_append_word(output: UnsafePointer[UInt8, MutAnyOrigin], at_arg: Int64, text: String, emit: Bool) -> Int64:
    var at = at_arg
    if at > 0:
        if emit: output[at] = 32
        at += 1
    return words_append_raw(output, at, text, emit)

fn words_small(n: UInt64, output: UnsafePointer[UInt8, MutAnyOrigin], at_arg: Int64, emit: Bool) -> Int64:
    var ones = InlineArray[String, 10]("")
    var teens = InlineArray[String, 10]("")
    var tens = InlineArray[String, 10]("")
    ones[0] = "zero"
    ones[1] = "one"
    ones[2] = "two"
    ones[3] = "three"
    ones[4] = "four"
    ones[5] = "five"
    ones[6] = "six"
    ones[7] = "seven"
    ones[8] = "eight"
    ones[9] = "nine"
    teens[0] = "ten"
    teens[1] = "eleven"
    teens[2] = "twelve"
    teens[3] = "thirteen"
    teens[4] = "fourteen"
    teens[5] = "fifteen"
    teens[6] = "sixteen"
    teens[7] = "seventeen"
    teens[8] = "eighteen"
    teens[9] = "nineteen"
    tens[0] = ""
    tens[1] = ""
    tens[2] = "twenty"
    tens[3] = "thirty"
    tens[4] = "forty"
    tens[5] = "fifty"
    tens[6] = "sixty"
    tens[7] = "seventy"
    tens[8] = "eighty"
    tens[9] = "ninety"
    var at = at_arg
    if n < 10: return words_append_word(output, at, ones[n], emit)
    if n < 20: return words_append_word(output, at, teens[n - 10], emit)
    at = words_append_word(output, at, tens[n / 10], emit)
    if n % 10 != 0:
        if emit: output[at] = 45
        at += 1
        at = words_append_raw(output, at, ones[n % 10], emit)
    return at

fn words_number(n_arg: UInt64, system: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], at_arg: Int64, depth: Int64, emit: Bool) -> Int64:
    if depth > 8: return at_arg
    var n = n_arg
    let initial = at_arg
    var at = at_arg
    let scale_count = 5 if system == 1 else 6
    for i in range(scale_count):
        let scale = words_scale_value(system, i)
        let group = n / scale
        n %= scale
        if group == 0: continue
        if group >= 100: at = words_number(group, system, output, at, depth + 1, emit)
        else: at = words_small(group, output, at, emit)
        at = words_append_word(output, at, words_scale_name(system, i), emit)
    if n != 0 or at == initial: at = words_small(n, output, at, emit)
    return at

@export("convert_number_to_words")
fn convert_number_to_words(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2 or input[1] < 0 or input[1] > 2: return -1
    let system = input[1]
    let number = input[0]
    let limit: Int64 = 999999999999999999 if system == 0 else 9000000000000000000
    if number < -limit or number > limit: return -1
    let magnitude = UInt64(-number) if number < 0 else UInt64(number)
    var required: Int64 = 0
    if number < 0: required = words_append_word(output, required, "negative", False)
    required = words_number(magnitude, system, output, required, 0, False)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < required: return -2
    var written: Int64 = 0
    if number < 0: written = words_append_word(output, written, "negative", True)
    written = words_number(magnitude, system, output, written, 0, True)
    return written
