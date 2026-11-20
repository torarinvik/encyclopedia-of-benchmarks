package posit8_rational_encoder

import "core:c"

MAX_COUNT :: 32
MAX_WORDS :: 66

positive_units :: proc "contextless" (code: u8) -> u64 {
    cursor: i32 = 6
    regime_bit := (code >> 6) & 1
    run: i32 = 0
    for cursor >= 0 && ((code >> cursor) & 1) == regime_bit {
        run += 1
        cursor -= 1
    }
    regime := i32(0)
    if regime_bit != 0 { regime = run - 1 } else { regime = -run }
    if cursor >= 0 { cursor -= 1 }
    exponent: i32 = 0
    for _ in 0..<2 {
        exponent <<= 1
        if cursor >= 0 {
            exponent |= i32((code >> cursor) & 1)
            cursor -= 1
        }
    }
    width := cursor + 1
    fraction: i32 = 0
    if width > 0 { fraction = i32(code & u8((1 << width) - 1)) }
    significand := (1 << width) + fraction
    shift := 4 * regime + exponent + 24 - width
    return u64(significand) << u32(shift)
}

compare_ratio_to_unit :: proc "contextless" (scaled, denominator, unit: u64) -> i32 {
    quotient := scaled / denominator
    remainder := scaled % denominator
    if quotient < unit do return -1
    if quotient > unit do return 1
    if remainder == 0 do return 0
    return 1
}

encode_one :: proc "contextless" (numerator, denominator: i64) -> u8 {
    if numerator == 0 { return 0 }
    negative := numerator < 0
    magnitude := u64(if negative { -numerator } else { numerator })
    scaled := magnitude << 24
    chosen: u8 = 0
    if compare_ratio_to_unit(scaled, u64(denominator), 1) <= 0 {
        chosen = 1
    } else if compare_ratio_to_unit(scaled, u64(denominator), positive_units(127)) >= 0 {
        chosen = 127
    } else {
        low, high := i32(1), i32(127)
        for low < high {
            middle := low + (high - low) / 2
            if compare_ratio_to_unit(scaled, u64(denominator), positive_units(u8(middle))) > 0 { low = middle + 1 } else { high = middle }
        }
        upper, lower := u8(low), u8(low - 1)
        midpoint := positive_units(lower) + positive_units(upper)
        midpoint_comparison := compare_ratio_to_unit(scaled << 1, u64(denominator), midpoint)
        if midpoint_comparison < 0 { chosen = lower }
        else if midpoint_comparison > 0 { chosen = upper }
        else if (lower & 1) == 0 { chosen = lower }
        else { chosen = upper }
    }
    if negative { return u8(256 - i64(chosen)) }
    return chosen
}

@(export)
posit8_rational_encoder :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_WORDS do return -1
    raw_count := input[0]
    if raw_count < 0 || raw_count > MAX_COUNT || length != c.size_t(1 + raw_count * 2) do return -1
    count := int(raw_count)
    for index in 0..<count {
        numerator, denominator := input[1 + 2 * index], input[2 + 2 * index]
        if numerator < -2147483648 || numerator > 2147483648 || denominator < 1 || denominator > 2147483648 do return -1
    }
    if output == nil || capacity < c.size_t(count) do return -2
    staged: [MAX_COUNT]u8{}
    for index in 0..<count { staged[index] = encode_one(input[1 + 2 * index], input[2 + 2 * index]) }
    for index in 0..<count { output[index] = staged[index] }
    return i64(count)
}
