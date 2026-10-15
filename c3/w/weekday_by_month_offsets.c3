module weekday_by_month_offsets;

fn bool is_leap_year(long year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
}

fn long month_offset(long month) {
    switch (month) {
        case 1: return 0;
        case 2: return 3;
        case 3: return 2;
        case 4: return 5;
        case 5: return 0;
        case 6: return 3;
        case 7: return 5;
        case 8: return 1;
        case 9: return 4;
        case 10: return 6;
        case 11: return 2;
        case 12: return 4;
        default: return -1;
    }
}

fn long weekday_by_month_offsets(long* values, usz length)
        @export("weekday_by_month_offsets") {
    if (values == null || length != 3) return -1;
    long year = values[0], month = values[1], day = values[2];
    if (year < 100 || year > 9999 || month < 1 || month > 12) return -1;
    bool leap = is_leap_year(year);
    long days_in_month = month == 2 ? (leap ? 29 : 28)
        : (month == 4 || month == 6 || month == 9 || month == 11 ? 30 : 31);
    if (day < 1 || day > days_in_month) return -1;

    long adjusted_year = year - (month < 3 ? 1 : 0);
    return (adjusted_year + adjusted_year / 4 - adjusted_year / 100
        + adjusted_year / 400 + month_offset(month) + day) % 7;
}
