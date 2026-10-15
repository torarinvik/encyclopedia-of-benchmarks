/// Return 1 for a positive Gregorian leap year, 0 otherwise, or -1 for invalid years.
export fn leap_year(year: i64) i64 {
    if (year <= 0) return -1;
    return if (@mod(year, 400) == 0 or (@mod(year, 4) == 0 and @mod(year, 100) != 0)) 1 else 0;
}
