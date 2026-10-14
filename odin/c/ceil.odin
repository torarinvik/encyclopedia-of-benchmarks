package ceil

import "core:c"

MAX_VALUES :: 256
MAX_INPUT_VALUES :: 1 + 2 * MAX_VALUES
NUMERATOR_LIMIT :: i64(1_000_000_000_000)
DENOMINATOR_LIMIT :: i64(1_000_000)
RESULT_OFFSET :: i64(1_000_000_000_001)

ceil_division :: proc "contextless" (numerator, denominator: i64) -> i64 {
    if numerator >= 0 {
        quotient := numerator / denominator
        if numerator % denominator != 0 { quotient += 1 }
        return quotient
    }
    return -((-numerator) / denominator)
}

@(export)
ceil_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 1 || length > MAX_INPUT_VALUES do return -1
    count_value := values[0]
    if count_value < 0 || count_value > MAX_VALUES do return -1
    count := int(count_value)
    if int(length) != 1 + 2 * count do return -1
    for i := 0; i < count; i += 1 {
        numerator := values[1 + 2 * i]
        denominator := values[2 + 2 * i]
        if numerator < -NUMERATOR_LIMIT || numerator > NUMERATOR_LIMIT ||
            denominator < 1 || denominator > DENOMINATOR_LIMIT {
            return -1
        }
    }
    checksum := i64(0)
    for i := 0; i < count; i += 1 {
        result := ceil_division(values[1 + 2 * i], values[2 + 2 * i])
        checksum += i64(i + 1) * (result + RESULT_OFFSET)
    }
    return checksum
}
