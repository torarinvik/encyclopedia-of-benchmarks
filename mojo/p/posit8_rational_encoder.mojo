from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_COUNT: Int = 32
const MAX_WORDS: Int = 66

def posit8_positive_units(code: Int) -> UInt64:
    var cursor = 6
    let regime_bit = (code >> cursor) & 1
    var run = 0
    while cursor >= 0 and ((code >> cursor) & 1) == regime_bit:
        run += 1
        cursor -= 1
    let regime = if regime_bit == 1: run - 1 else: -run
    if cursor >= 0:
        cursor -= 1
    var exponent = 0
    for _ in range(2):
        exponent <<= 1
        if cursor >= 0:
            exponent |= (code >> cursor) & 1
            cursor -= 1
    let width = cursor + 1
    let fraction = if width == 0: 0 else: code & ((1 << width) - 1)
    let significand = (1 << width) + fraction
    let shift = 4 * regime + exponent + 24 - width
    return (significand.to_u64() << shift)

def posit8_compare_ratio_to_unit(scaled: UInt64, denominator: UInt64, unit: UInt64) -> Int:
    let quotient = scaled // denominator
    let remainder = scaled % denominator
    if quotient < unit:
        return -1
    if quotient > unit:
        return 1
    if remainder == 0:
        return 0
    return 1

def posit8_encode_one(numerator: Int64, denominator: Int64) -> UInt8:
    if numerator == 0:
        return 0
    let negative = numerator < 0
    let magnitude = if negative: (-numerator).to_u64() else: numerator.to_u64()
    let scaled = magnitude << 24
    var chosen: Int = 0
    if posit8_compare_ratio_to_unit(scaled, denominator.to_u64(), 1) <= 0:
        chosen = 1
    elif posit8_compare_ratio_to_unit(scaled, denominator.to_u64(), posit8_positive_units(127)) >= 0:
        chosen = 127
    else:
        var low = 1
        var high = 127
        while low < high:
            let middle = low + (high - low) // 2
            if posit8_compare_ratio_to_unit(scaled, denominator.to_u64(), posit8_positive_units(middle)) > 0:
                low = middle + 1
            else:
                high = middle
        let upper = low
        let lower = upper - 1
        let midpoint = posit8_positive_units(lower) + posit8_positive_units(upper)
        let midpoint_comparison = posit8_compare_ratio_to_unit(scaled << 1, denominator.to_u64(), midpoint)
        if midpoint_comparison < 0:
            chosen = lower
        elif midpoint_comparison > 0:
            chosen = upper
        elif lower % 2 == 0:
            chosen = lower
        else:
            chosen = upper
    if negative:
        return (256 - chosen).to_u8()
    return chosen.to_u8()

@export("posit8_rational_encoder")
fn posit8_rational_encoder(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_WORDS:
        return -1
    let count_word = input[0]
    if count_word < 0 or count_word > MAX_COUNT or length.to_int() != 1 + count_word.to_int() * 2:
        return -1
    let count = count_word.to_int()
    for index in range(count):
        let numerator = input[1 + 2 * index]
        let denominator = input[2 + 2 * index]
        if numerator < -2147483648 or numerator > 2147483648 or denominator < 1 or denominator > 2147483648:
            return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < count:
        return -2
    var staged = InlineArray[UInt8, MAX_COUNT]()
    for index in range(count):
        staged[index] = posit8_encode_one(input[1 + 2 * index], input[2 + 2 * index])
    for index in range(count):
        output[index] = staged[index]
    return count.to_i64()
