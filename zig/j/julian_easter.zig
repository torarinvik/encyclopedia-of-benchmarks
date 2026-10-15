/// Meeus Julian Easter date encoded as YYYYMMDD.
export fn julian_easter(year: i64) i64 {
    if (year < 1 or year > 9999) return -1;
    const a = @rem(year, 4);
    const b = @rem(year, 7);
    const c = @rem(year, 19);
    const d = @rem(19 * c + 15, 30);
    const e = @rem(2 * a + 4 * b - d + 34, 7);
    const day_of_year = d + e + 114;
    const month = @divTrunc(day_of_year, 31);
    const day = @rem(day_of_year, 31) + 1;
    return year * 10000 + month * 100 + day;
}
