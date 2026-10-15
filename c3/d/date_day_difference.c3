module date_day_difference;

const usz MAX_LENGTH = 21;
const long INVALID_ORDINAL = -1000000000;

fn long floor_div(long value, long divisor) {
    long quotient = value / divisor;
    if (value % divisor != 0 && value < 0) quotient--;
    return quotient;
}

fn bool leap_year(long year) {
    return year % 400 == 0 || (year % 100 != 0 && year % 4 == 0);
}

fn long month_length(long month, long year) {
    if (month == 2) return leap_year(year) ? 29 : 28;
    if (month == 4 || month == 6 || month == 9 || month == 11) return 30;
    return 31;
}

fn long date_ordinal(long day, long month, long year) {
    long prior = year - 1;
    long adjustment = month <= 2 ? 0 : (leap_year(year) ? -1 : -2);
    return 365 * prior + floor_div(prior, 4) - floor_div(prior, 100) + floor_div(prior, 400) +
           day + floor_div(367 * month - 362, 12) + adjustment;
}

fn long parse_date(long* values, usz start, usz end) {
    usz pos = start;
    long day = 0, month = 0, year = 0;
    usz digits = 0;
    while (pos < end && values[pos] >= 48 && values[pos] <= 57 && digits < 3) {
        day = day * 10 + values[pos] - 48;
        digits++;
        pos++;
    }
    if (digits < 1 || digits > 2 || pos >= end || values[pos] != 47) return INVALID_ORDINAL;
    pos++;
    digits = 0;
    while (pos < end && values[pos] >= 48 && values[pos] <= 57 && digits < 3) {
        month = month * 10 + values[pos] - 48;
        digits++;
        pos++;
    }
    if (digits < 1 || digits > 2 || pos >= end || values[pos] != 47) return INVALID_ORDINAL;
    pos++;
    if (end - pos != 4) return INVALID_ORDINAL;
    while (pos < end) {
        if (values[pos] < 48 || values[pos] > 57) return INVALID_ORDINAL;
        year = year * 10 + values[pos] - 48;
        pos++;
    }
    if (month < 1 || month > 12 || day < 1 || day > month_length(month, year)) return INVALID_ORDINAL;
    return date_ordinal(day, month, year);
}

// Return the absolute day difference; malformed packed dates return -1.
fn long date_day_difference(long* values, usz length) @export("date_day_difference") {
    if (length < 17 || length > MAX_LENGTH || values == null) return -1;
    usz separator = length;
    for (usz i = 0; i < length; i++) {
        if (values[i] == 124) {
            if (separator != length) return -1;
            separator = i;
        }
    }
    if (separator == length) return -1;
    long first = parse_date(values, 0, separator);
    long second = parse_date(values, separator + 1, length);
    if (first == INVALID_ORDINAL || second == INVALID_ORDINAL) return -1;
    return first > second ? first - second : second - first;
}
