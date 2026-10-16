module gauss_easter;

fn long positive_mod(long value, long modulus) {
    long result = value % modulus;
    return result < 0 ? result + modulus : result;
}

fn long gauss_easter(long year) @export("gauss_easter") {
    if (year < 1 || year > 9999) return -1;
    long a = year % 19, b = year % 4, c = year % 7;
    long century = year / 100;
    long lunar_correction = (13 + 8 * century) / 25;
    long moon_q = positive_mod(60 - 4 * lunar_correction + 3 * century, 120);
    long start_q = positive_mod(16 + 3 * century, 28);
    long add_q = positive_mod(76 * a + moon_q, 120);
    long sunday_q = positive_mod(8 * b + 16 * c + start_q + 6 * add_q, 28);
    long month, day;
    if (add_q == 116 && sunday_q == 24) { month = 4; day = 19; }
    else if (add_q == 112 && sunday_q == 24) { month = 4; day = 18; }
    else {
        long march_day = 22 + (add_q + sunday_q) / 4;
        if (march_day <= 31) { month = 3; day = march_day; }
        else { month = 4; day = march_day - 31; }
    }
    return year * 10000 + month * 100 + day;
}
