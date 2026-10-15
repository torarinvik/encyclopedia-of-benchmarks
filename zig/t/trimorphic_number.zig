/// Check whether n cubed ends with the decimal digits of n.
export fn trimorphic_number(number: i64) i64 {
    if (number < 0 or number > 2_000_000) return -1;
    var modulus: i64 = 10;
    var digits = number;
    while (digits >= 10) {
        digits = @divTrunc(digits, 10);
        modulus *= 10;
    }
    const cube = number * number * number;
    return if (@mod(cube, modulus) == number) 1 else 0;
}
