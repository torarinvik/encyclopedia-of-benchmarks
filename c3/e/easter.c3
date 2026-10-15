module easter;

fn long easter(long year) @export("easter")
{
    if (year < 0 || year > 9999) return -1;
    if (year <= 1582) return 0;

    long a = year % 19;
    long b = year / 100;
    long c = year % 100;
    long d = b / 4;
    long e = b % 4;
    long f = (b + 8) / 25;
    long g = (b - f + 1) / 3;
    long h = (19 * a + b - d - g + 15) % 30;
    long i = c / 4;
    long k = c % 4;
    long r = (32 + 2 * e + 2 * i - h - k) % 7;
    long m = (a + 11 * h + 22 * r) / 451;
    long date = h + r - 7 * m + 114;
    long month = date / 31;
    long day = date % 31 + 1;
    return month * 100 + day;
}
