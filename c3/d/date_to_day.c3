module date_to_day;

// Return the English weekday name for a bounded ASCII d/m/yyyy date.
fn long date_to_day(long* input, usz length, char* output, usz output_capacity)
        @export("date_to_day") {
    if (input == null || length < 9 || length > 11 || input[length - 1] != 0) return -1;
    usz date_length = length - 1;
    usz cursor = 0;
    long[3] fields = {};
    for (usz field = 0; field < 3; field++) {
        usz start = cursor;
        long value = 0;
        while (cursor < date_length && input[cursor] >= 48 && input[cursor] <= 57) {
            value = value * 10 + input[cursor] - 48;
            cursor++;
        }
        usz digits = cursor - start;
        usz max_digits = field == 2 ? 4 : 2;
        if (digits == 0 || digits > max_digits || (field == 2 && digits != 4)) return -1;
        fields[field] = value;
        if (field < 2) {
            if (cursor >= date_length || input[cursor] != 47) return -1;
            cursor++;
        }
    }
    if (cursor != date_length) return -1;
    long day = fields[0], month = fields[1], year = fields[2];
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) return -1;
    bool leap = year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
    int[12] month_days = {31,28,31,30,31,30,31,31,30,31,30,31};
    if (leap) month_days[1] = 29;
    if (day > month_days[month - 1]) return -1;

    long adjusted_year = year, adjusted_month = month;
    if (adjusted_month < 3) { adjusted_year--; adjusted_month += 12; }
    long year_of_century = adjusted_year % 100;
    long century = adjusted_year / 100;
    long weekday = (day + ((adjusted_month + 1) * 26) / 10 + year_of_century +
        year_of_century / 4 + century / 4 + 5 * century) % 7;
    char*[7] names = {"Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"};
    usz[7] name_lengths = {8, 6, 6, 7, 9, 8, 6};
    usz name_length = name_lengths[weekday];
    if (output_capacity < name_length || output == null) return -2;
    for (usz index = 0; index < name_length; index++) output[index] = names[weekday][index];
    return (long)name_length;
}
