/// Return the nth hexagonal number for a JS-safe positive index.
export fn hexagonal_number(number: i64) i64 {
    if (number < 1 or number > 67_108_864) return -1;
    return number * (2 * number - 1);
}
