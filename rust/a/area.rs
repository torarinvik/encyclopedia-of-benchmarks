const MAX_OPERATIONS: usize = 256;
const DIMENSION_LIMIT: i64 = 1000;
const RESULT_OFFSET: i64 = 1_000_000_007;

fn integer_sqrt(value: i64) -> i64 {
    let (mut low, mut high, mut answer) = (0i64, 3_037_000_499i64, 0i64);
    while low <= high {
        let middle = low + (high - low) / 2;
        if middle == 0 || middle <= value / middle {
            answer = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    answer
}

fn scale_pi(value: i64) -> i64 {
    value * 3 + value * 141_592_654 / 1_000_000_000
}

fn scale_pi_squared(value: i64) -> i64 {
    value * 9 + value * 869_604_401 / 1_000_000_000
}

fn regular_polygon_coefficient(sides: i64) -> i64 {
    match sides {
        3 => 433_012_701, 4 => 1_000_000_000, 5 => 1_720_477_400, 6 => 2_598_076_211,
        7 => 3_633_912_444, 8 => 4_828_427_124, 9 => 6_181_824_193, 10 => 7_694_208_842,
        11 => 9_365_639_906, 12 => 11_196_152_422, 13 => 13_185_768_328, 14 => 15_334_501_936,
        15 => 17_642_362_910, 16 => 20_109_357_968, 17 => 22_735_491_898, 18 => 25_520_768_188,
        19 => 28_465_189_427, 20 => 31_568_757_573, 21 => 34_831_474_123, 22 => 38_253_340_244,
        23 => 41_834_356_852, 24 => 45_574_524_676, 25 => 49_473_844_301, 26 => 53_532_316_204,
        27 => 57_749_940_771, 28 => 62_126_718_324, 29 => 66_662_649_129, 30 => 71_357_733_406,
        31 => 76_211_971_344, 32 => 81_225_363_100,
        _ => -1,
    }
}

fn area_milli(operation: i64, a: i64, b: i64, c: i64) -> i64 {
    match operation {
        0 => a * a * 1000,
        1 => a * b * 1000,
        2 => a * b * 500,
        3 => scale_pi(a * a * 1000),
        4 => a * b * 1000,
        5 => (a + b) * c * 500,
        6 => {
            let perimeter = a + b + c;
            if a + b < c || a + c < b || b + c < a { return -1; }
            let radicand = perimeter * (perimeter - 2 * a)
                * (perimeter - 2 * b) * (perimeter - 2 * c);
            integer_sqrt(radicand * 1_000_000) / 4
        }
        7 => scale_pi(a * b * 1000),
        8 => a * b * 500,
        9 => 6 * a * a * 1000,
        10 => 2 * (a * b + a * c + b * c) * 1000,
        11 => scale_pi(4 * a * a * 1000),
        12 => scale_pi(3 * a * a * 1000),
        13 => scale_pi(2 * a * (b + a) * 1000),
        14 => scale_pi(2 * a * b * 1000),
        15 => {
            let slant_milli = integer_sqrt((a * a + b * b) * 1_000_000);
            scale_pi(a * a * 1000 + a * slant_milli)
        }
        16 => {
            let slant_milli = integer_sqrt((a * a + b * b) * 1_000_000);
            scale_pi(a * slant_milli)
        }
        17 => (a * a + 2 * a * b) * 1000,
        18 => {
            let difference = if a >= b { a - b } else { b - a };
            let slant_milli = integer_sqrt((c * c + difference * difference) * 1_000_000);
            scale_pi((a * a + b * b) * 1000 + (a + b) * slant_milli)
        }
        19 => scale_pi_squared(4 * a * b * 1000),
        20 => {
            let coefficient = regular_polygon_coefficient(a);
            if coefficient < 0 { return -1; }
            coefficient * b * b / 1_000_000
        }
        21 => {
            let coefficient = regular_polygon_coefficient(a);
            if coefficient < 0 { return -1; }
            2 * (coefficient * b * b / 1_000_000) + a * b * c * 1000
        }
        _ => -1,
    }
}

#[no_mangle]
pub unsafe extern "C" fn area_benchmark(values: *const i64, length: usize) -> i64 {
    if length < 1 || length > 1 + 4 * MAX_OPERATIONS { return -1; }
    let count_value = *values;
    if count_value < 0 || count_value > MAX_OPERATIONS as i64
        || length != 1 + 4 * count_value as usize { return -1; }
    let mut checksum = 0i64;
    for index in 0..count_value as usize {
        let position = 1 + 4 * index;
        let operation = *values.add(position);
        let a = *values.add(position + 1);
        let b = *values.add(position + 2);
        let c = *values.add(position + 3);
        if !(0..=21).contains(&operation) || !(0..=DIMENSION_LIMIT).contains(&a)
            || !(0..=DIMENSION_LIMIT).contains(&b) || !(0..=DIMENSION_LIMIT).contains(&c) { return -1; }
        if (operation == 0 || operation == 3 || operation == 9 || operation == 11 || operation == 12)
            && (b != 0 || c != 0) { return -1; }
        if ((1..=2).contains(&operation) || operation == 4 || (7..=8).contains(&operation)
            || (13..=17).contains(&operation) || operation == 19 || operation == 20) && c != 0 { return -1; }
        let result = area_milli(operation, a, b, c);
        if result < 0 { return -1; }
        checksum += (index as i64 + 1) * (result + RESULT_OFFSET);
    }
    checksum
}
