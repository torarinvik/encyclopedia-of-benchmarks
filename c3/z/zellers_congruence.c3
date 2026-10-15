module zellers_congruence;

fn bool is_leap_year(long year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

fn long zellers_congruence(long* date, usz length) @export("zellers_congruence") {
    if (date == null || length != 3) return -1;
    long year = date[0], month = date[1], day = date[2];
    if (year < 46 || year > 8499 || month < 1 || month > 12 || day < 1) return -1;
    long maximum_day = 31;
    if (month == 4 || month == 6 || month == 9 || month == 11) maximum_day = 30;
    if (month == 2) maximum_day = is_leap_year(year) ? 29 : 28;
    if (day > maximum_day) return -1;

    if (month <= 2) { year--; month += 12; }
    long century = year / 100;
    long year_of_century = year % 100;
    long month_term = (260 * month - 539) / 100;
    long total = day + year_of_century + month_term + century / 4 + year_of_century / 4 - 2 * century;
    long weekday = total % 7;
    if (weekday < 0) weekday += 7;
    return weekday;
}
