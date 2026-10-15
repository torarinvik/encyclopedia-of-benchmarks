module get_month_days;

fn bool is_leap_year(long year) {
    return year % 400L == 0L || (year % 100L != 0L && year % 4L == 0L);
}

// Return the pinned JavaScript helper's month length.
fn long get_month_days(long month_number, long year) @export("get_month_days") {
    if (year < 0L || year > 9999L) return -1L;
    switch (month_number) {
        case 1L, 3L, 5L, 7L, 8L, 10L, 12L: return 31L;
        case 4L, 6L, 9L, 11L: return 30L;
        case 2L: return is_leap_year(year) ? 29L : 28L;
        default: return -1L;
    }
}
