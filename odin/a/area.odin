package area

import "core:c"

MAX_OPERATIONS :: 256
DIMENSION_LIMIT :: i64(1000)
RESULT_OFFSET :: i64(1_000_000_007)

integer_sqrt :: proc "contextless" (value: i64) -> i64 {
    low := i64(0)
    high := i64(3_037_000_499)
    answer := i64(0)
    for low <= high {
        middle := low + (high - low) / 2
        if middle == 0 || middle <= value / middle {
            answer = middle
            low = middle + 1
        } else {
            high = middle - 1
        }
    }
    return answer
}

scale_pi :: proc "contextless" (value: i64) -> i64 {
    return value * 3 + value * 141_592_654 / 1_000_000_000
}

scale_pi_squared :: proc "contextless" (value: i64) -> i64 {
    return value * 9 + value * 869_604_401 / 1_000_000_000
}

regular_polygon_coefficient :: proc "contextless" (sides: i64) -> i64 {
    if sides == 3 do return 433_012_701
    if sides == 4 do return 1_000_000_000
    if sides == 5 do return 1_720_477_400
    if sides == 6 do return 2_598_076_211
    if sides == 7 do return 3_633_912_444
    if sides == 8 do return 4_828_427_124
    if sides == 9 do return 6_181_824_193
    if sides == 10 do return 7_694_208_842
    if sides == 11 do return 9_365_639_906
    if sides == 12 do return 11_196_152_422
    if sides == 13 do return 13_185_768_328
    if sides == 14 do return 15_334_501_936
    if sides == 15 do return 17_642_362_910
    if sides == 16 do return 20_109_357_968
    if sides == 17 do return 22_735_491_898
    if sides == 18 do return 25_520_768_188
    if sides == 19 do return 28_465_189_427
    if sides == 20 do return 31_568_757_573
    if sides == 21 do return 34_831_474_123
    if sides == 22 do return 38_253_340_244
    if sides == 23 do return 41_834_356_852
    if sides == 24 do return 45_574_524_676
    if sides == 25 do return 49_473_844_301
    if sides == 26 do return 53_532_316_204
    if sides == 27 do return 57_749_940_771
    if sides == 28 do return 62_126_718_324
    if sides == 29 do return 66_662_649_129
    if sides == 30 do return 71_357_733_406
    if sides == 31 do return 76_211_971_344
    if sides == 32 do return 81_225_363_100
    return -1
}

area_milli :: proc "contextless" (operation, a, b, c: i64) -> i64 {
    if operation == 0 do return a * a * 1000
    if operation == 1 do return a * b * 1000
    if operation == 2 do return a * b * 500
    if operation == 3 do return scale_pi(a * a * 1000)
    if operation == 4 do return a * b * 1000
    if operation == 5 do return (a + b) * c * 500
    if operation == 6 {
        perimeter := a + b + c
        if a + b < c || a + c < b || b + c < a do return -1
        radicand := perimeter * (perimeter - 2 * a) * (perimeter - 2 * b) * (perimeter - 2 * c)
        return integer_sqrt(radicand * 1_000_000) / 4
    }
    if operation == 7 do return scale_pi(a * b * 1000)
    if operation == 8 do return a * b * 500
    if operation == 9 do return 6 * a * a * 1000
    if operation == 10 do return 2 * (a * b + a * c + b * c) * 1000
    if operation == 11 do return scale_pi(4 * a * a * 1000)
    if operation == 12 do return scale_pi(3 * a * a * 1000)
    if operation == 13 do return scale_pi(2 * a * (b + a) * 1000)
    if operation == 14 do return scale_pi(2 * a * b * 1000)
    if operation == 15 do return scale_pi(a * a * 1000 + a * integer_sqrt((a * a + b * b) * 1_000_000))
    if operation == 16 do return scale_pi(a * integer_sqrt((a * a + b * b) * 1_000_000))
    if operation == 17 do return (a * a + 2 * a * b) * 1000
    if operation == 18 {
        difference := a - b
        if difference < 0 do difference = -difference
        slant_milli := integer_sqrt((c * c + difference * difference) * 1_000_000)
        return scale_pi((a * a + b * b) * 1000 + (a + b) * slant_milli)
    }
    if operation == 19 do return scale_pi_squared(4 * a * b * 1000)
    if operation == 20 {
        coefficient := regular_polygon_coefficient(a)
        if coefficient < 0 do return -1
        return coefficient * b * b / 1_000_000
    }
    if operation == 21 {
        coefficient := regular_polygon_coefficient(a)
        if coefficient < 0 do return -1
        return 2 * (coefficient * b * b / 1_000_000) + a * b * c * 1000
    }
    return -1
}

@(export)
area_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 1 || length > 1025 do return -1
    count_value := values[0]
    if count_value < 0 || count_value > MAX_OPERATIONS || int(length) != 1 + 4 * int(count_value) do return -1
    checksum := i64(0)
    for index := 0; index < int(count_value); index += 1 {
        position := 1 + 4 * index
        operation := values[position]
        a, b, c := values[position + 1], values[position + 2], values[position + 3]
        if operation < 0 || operation > 21 || a < 0 || a > DIMENSION_LIMIT || b < 0 || b > DIMENSION_LIMIT || c < 0 || c > DIMENSION_LIMIT do return -1
        if (operation == 0 || operation == 3 || operation == 9 || operation == 11 || operation == 12) && (b != 0 || c != 0) do return -1
        if ((operation >= 1 && operation <= 2) || operation == 4 || (operation >= 7 && operation <= 8) || (operation >= 13 && operation <= 17) || operation == 19 || operation == 20) && c != 0 do return -1
        result := area_milli(operation, a, b, c)
        if result < 0 do return -1
        checksum += i64(index + 1) * (result + RESULT_OFFSET)
    }
    return checksum
}
