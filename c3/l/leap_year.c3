module leap_year;

// Return 1 for a positive Gregorian leap year, 0 otherwise, or -1 for invalid years.
fn long leap_year(long year) @export("leap_year") {
    if (year <= 0) { return -1; }
    return (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)) ? 1 : 0;
}
