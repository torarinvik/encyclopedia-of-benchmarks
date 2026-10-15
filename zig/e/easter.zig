/// Gregorian Easter date, packed as month * 100 + day.
export fn easter(year: i64) i64 {
    if (year < 0 or year > 9999) return -1;
    if (year <= 1582) return 0;
    const a = @mod(year, 19);
    const b = @divTrunc(year, 100);
    const c = @mod(year, 100);
    const d = @divTrunc(b, 4);
    const e = @mod(b, 4);
    const f = @divTrunc(b + 8, 25);
    const g = @divTrunc(b - f + 1, 3);
    const h = @mod(19 * a + b - d - g + 15, 30);
    const i = @divTrunc(c, 4);
    const k = @mod(c, 4);
    const r = @mod(32 + 2 * e + 2 * i - h - k, 7);
    const m = @divTrunc(a + 11 * h + 22 * r, 451);
    const date = h + r - 7 * m + 114;
    const month = @divTrunc(date, 31);
    const day = @mod(date, 31) + 1;
    return month * 100 + day;
}
