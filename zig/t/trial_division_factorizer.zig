export fn trial_division_factorizer(input: i64) i64 {
    if (input < -2_147_483_648 or input > 2_147_483_647 or input == 0 or input == -2_147_483_648) return -1;
    const number = if (input < 0) -input else input;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(number, divisor)) : (divisor += 1) {
        if (@mod(number, divisor) == 0) return divisor;
    }
    return 0;
}
