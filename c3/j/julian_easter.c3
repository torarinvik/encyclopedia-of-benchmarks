module julian_easter;

// Meeus Julian Easter date encoded as YYYYMMDD.
fn long julian_easter(long year) @export("julian_easter")
{
    if (year < 1 || year > 9999) return -1;
    long a = year % 4;
    long b = year % 7;
    long c = year % 19;
    long d = (19 * c + 15) % 30;
    long e = (2 * a + 4 * b - d + 34) % 7;
    long day_of_year = d + e + 114;
    long month = day_of_year / 31;
    long day = day_of_year % 31 + 1;
    return year * 10000 + month * 100 + day;
}
