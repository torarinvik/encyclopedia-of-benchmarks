const MAX_OPERATIONS: usize = 256;
const DIMENSION_LIMIT: i64 = 1000;
const RESULT_OFFSET: i64 = 1_000_000_007;

fn integerSqrt(value: i64) i64 {
    var low: i64 = 0;
    var high: i64 = 3_037_000_499;
    var answer: i64 = 0;
    while (low <= high) {
        const middle = low + @divTrunc(high - low, 2);
        if (middle == 0 or middle <= @divTrunc(value, middle)) {
            answer = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return answer;
}

fn scalePi(value: i64) i64 {
    return value * 3 + @divTrunc(value * 141_592_654, 1_000_000_000);
}

fn scalePiSquared(value: i64) i64 {
    return value * 9 + @divTrunc(value * 869_604_401, 1_000_000_000);
}

fn regularPolygonCoefficient(sides: i64) i64 {
    return switch (sides) {
        3 => 433_012_701, 4 => 1_000_000_000, 5 => 1_720_477_400, 6 => 2_598_076_211,
        7 => 3_633_912_444, 8 => 4_828_427_124, 9 => 6_181_824_193, 10 => 7_694_208_842,
        11 => 9_365_639_906, 12 => 11_196_152_422, 13 => 13_185_768_328, 14 => 15_334_501_936,
        15 => 17_642_362_910, 16 => 20_109_357_968, 17 => 22_735_491_898, 18 => 25_520_768_188,
        19 => 28_465_189_427, 20 => 31_568_757_573, 21 => 34_831_474_123, 22 => 38_253_340_244,
        23 => 41_834_356_852, 24 => 45_574_524_676, 25 => 49_473_844_301, 26 => 53_532_316_204,
        27 => 57_749_940_771, 28 => 62_126_718_324, 29 => 66_662_649_129, 30 => 71_357_733_406,
        31 => 76_211_971_344, 32 => 81_225_363_100,
        else => -1,
    };
}

fn regularPolygonAreaMilli(sides: i64, side: i64) i64 {
    const coefficient = regularPolygonCoefficient(sides);
    if (coefficient < 0) return -1;
    return @divTrunc(coefficient * side * side, 1_000_000);
}

fn regularPrismSurfaceMilli(sides: i64, side: i64, height: i64) i64 {
    const coefficient = regularPolygonCoefficient(sides);
    if (coefficient < 0) return -1;
    const base_area = @divTrunc(coefficient * side * side, 1_000_000);
    return 2 * base_area + sides * side * height * 1000;
}

fn areaMilli(operation: i64, a: i64, b: i64, c: i64) i64 {
    return switch (operation) {
        0 => a * a * 1000,
        1 => a * b * 1000,
        2 => a * b * 500,
        3 => scalePi(a * a * 1000),
        4 => a * b * 1000,
        5 => (a + b) * c * 500,
        6 => blk: {
            const perimeter = a + b + c;
            if (a + b < c or a + c < b or b + c < a) break :blk -1;
            const radicand = perimeter * (perimeter - 2 * a) * (perimeter - 2 * b) * (perimeter - 2 * c);
            break :blk @divTrunc(integerSqrt(radicand * 1_000_000), 4);
        },
        7 => scalePi(a * b * 1000),
        8 => a * b * 500,
        9 => 6 * a * a * 1000,
        10 => 2 * (a * b + a * c + b * c) * 1000,
        11 => scalePi(4 * a * a * 1000),
        12 => scalePi(3 * a * a * 1000),
        13 => scalePi(2 * a * (b + a) * 1000),
        14 => scalePi(2 * a * b * 1000),
        15 => scalePi(a * a * 1000 + a * integerSqrt((a * a + b * b) * 1_000_000)),
        16 => scalePi(a * integerSqrt((a * a + b * b) * 1_000_000)),
        17 => (a * a + 2 * a * b) * 1000,
        18 => blk: {
            const difference = if (a >= b) a - b else b - a;
            const slant_milli = integerSqrt((c * c + difference * difference) * 1_000_000);
            break :blk scalePi((a * a + b * b) * 1000 + (a + b) * slant_milli);
        },
        19 => scalePiSquared(4 * a * b * 1000),
        20 => regularPolygonAreaMilli(a, b),
        21 => regularPrismSurfaceMilli(a, b, c),
        else => -1,
    };
}

export fn area_benchmark(values: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 1 + 4 * MAX_OPERATIONS) return -1;
    const count_value = values[0];
    if (count_value < 0 or count_value > MAX_OPERATIONS or
        length != 1 + 4 * @as(usize, @intCast(count_value))) return -1;
    var checksum: i64 = 0;
    for (0..@as(usize, @intCast(count_value))) |index| {
        const position = 1 + 4 * index;
        const operation = values[position];
        const a = values[position + 1];
        const b = values[position + 2];
        const c = values[position + 3];
        if (operation < 0 or operation > 21 or a < 0 or a > DIMENSION_LIMIT or
            b < 0 or b > DIMENSION_LIMIT or c < 0 or c > DIMENSION_LIMIT) return -1;
        if ((operation == 0 or operation == 3 or operation == 9 or operation == 11 or operation == 12) and
            (b != 0 or c != 0)) return -1;
        if (((operation >= 1 and operation <= 2) or operation == 4 or (operation >= 7 and operation <= 8) or
            (operation >= 13 and operation <= 17) or operation == 19 or operation == 20) and c != 0) return -1;
        const result = areaMilli(operation, a, b, c);
        if (result < 0) return -1;
        checksum += @as(i64, @intCast(index + 1)) * (result + RESULT_OFFSET);
    }
    return checksum;
}
