fn positiveMod(value: i64, modulus: i64) i64 {
    return @mod(value, modulus);
}

export fn gauss_easter(year: i64) i64 {
    if (year < 1 or year > 9999) return -1;
    const a = @mod(year, 19);
    const b = @mod(year, 4);
    const c = @mod(year, 7);
    const century = @divTrunc(year, 100);
    const lunar_correction = @divTrunc(13 + 8 * century, 25);
    const moon_q = positiveMod(60 - 4 * lunar_correction + 3 * century, 120);
    const start_q = positiveMod(16 + 3 * century, 28);
    const add_q = positiveMod(76 * a + moon_q, 120);
    const sunday_q = positiveMod(8 * b + 16 * c + start_q + 6 * add_q, 28);
    var month: i64 = 0;
    var day: i64 = 0;
    if (add_q == 116 and sunday_q == 24) {
        month = 4;
        day = 19;
    } else if (add_q == 112 and sunday_q == 24) {
        month = 4;
        day = 18;
    } else {
        const march_day = 22 + @divTrunc(add_q + sunday_q, 4);
        if (march_day <= 31) {
            month = 3;
            day = march_day;
        } else {
            month = 4;
            day = march_day - 31;
        }
    }
    return year * 10000 + month * 100 + day;
}
