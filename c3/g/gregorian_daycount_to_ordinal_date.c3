module gregorian_daycount_to_ordinal_date;

fn bool is_leap_year(long year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

fn void decode_offset(long offset, long *year_out, long *ordinal_out) {
    long shifted = offset + 719468;
    long era = shifted / 146097;
    long day_of_era = shifted - era * 146097;
    long year_of_era = (day_of_era - day_of_era / 1460 + day_of_era / 36524
        - day_of_era / 146096) / 365;
    long year = year_of_era + era * 400;
    long day_of_year_march = day_of_era
        - (365 * year_of_era + year_of_era / 4 - year_of_era / 100);
    long month_march = (5 * day_of_year_march + 2) / 153;
    long day = day_of_year_march - (153 * month_march + 2) / 5 + 1;
    long month = month_march + (month_march < 10 ? 3 : -9);
    if (month <= 2) year += 1;
    long[12] days_before_month = {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334};
    long leap_adjustment = 0;
    if (month > 2 && is_leap_year(year)) leap_adjustment = 1;
    long ordinal = days_before_month[(usz)(month - 1)] + leap_adjustment + day;
    *year_out = year;
    *ordinal_out = ordinal;
}

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long gregorian_daycount_to_ordinal_date(long *input, usz length, char *output,
        usz capacity) @export("gregorian_daycount_to_ordinal_date") {
    if (input == null || length < 1 || length > 2 || length != 1) return -1;
    long offset = input[0];
    if (offset < -146097 || offset > 146097) return -1;
    if (output == null || capacity < 16) return -2;
    long year = 0, ordinal = 0;
    decode_offset(offset, &year, &ordinal);
    store_i64_le(output, 0, year);
    store_i64_le(output, 8, ordinal);
    return 16;
}
