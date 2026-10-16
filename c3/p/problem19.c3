module problem19;

fn bool is_leap_year(long year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
}

fn long problem19(long ignored) @export("problem19") {
    if (ignored != 0) return -1;
    long weekday = 2; // 1 January 1901 was Tuesday; Sunday is 0.
    long count = 0;
    for (long year = 1901; year <= 2000; year++) {
        for (long month = 1; month <= 12; month++) {
            if (weekday == 0) count++;
            long days = 31;
            if (month == 4 || month == 6 || month == 9 || month == 11) days = 30;
            if (month == 2) days = is_leap_year(year) ? 29 : 28;
            weekday = (weekday + days) % 7;
        }
    }
    return count;
}
