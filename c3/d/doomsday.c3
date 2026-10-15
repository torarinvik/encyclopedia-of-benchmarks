module doomsday;

fn bool is_leap_year(long year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
}

fn long month_anchor(long month, bool leap) {
    switch (month) {
        case 1: return leap ? 4 : 3;
        case 2: return leap ? 1 : 7;
        case 3: return 7;
        case 4: return 4;
        case 5: return 2;
        case 6: return 6;
        case 7: return 4;
        case 8: return 1;
        case 9: return 5;
        case 10: return 3;
        case 11: return 7;
        case 12: return 5;
        default: return -1;
    }
}

fn long doomsday(long* values, usz length) @export("doomsday") {
    if (values == null || length != 3) return -1;
    long year = values[0], month = values[1], day = values[2];
    if (year < 100 || year > 9999 || month < 1 || month > 12) return -1;
    bool leap = is_leap_year(year);
    long days_in_month = month == 2 ? (leap ? 29 : 28)
        : (month == 4 || month == 6 || month == 9 || month == 11 ? 30 : 31);
    if (day < 1 || day > days_in_month) return -1;

    long within_century = year % 100;
    long century_anchor = (5 * ((year / 100) % 4) + 2) % 7;
    long doom = (within_century / 12 + within_century % 12
        + (within_century % 12) / 4 + century_anchor) % 7;
    long weekday = (doom + day - month_anchor(month, leap)) % 7;
    if (weekday < 0) weekday += 7;
    return weekday;
}
