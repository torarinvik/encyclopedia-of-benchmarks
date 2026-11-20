"""Integer Gauss computus reference for the bounded Gregorian date contract."""


def expected_result(year):
    if not 0 <= year <= 9999:
        return -1
    if year <= 1582:
        return 0
    century = year // 100
    a, b, c = year % 19, year % 4, year % 7
    solar = century // 4
    lunar = (13 + 8 * century) // 25
    m = (15 - lunar + century - solar) % 30
    n = (4 + century - solar) % 7
    d = (19 * a + m) % 30
    e = (2 * b + 4 * c + 6 * d + n) % 7
    if d == 29 and e == 6:
        return 419
    if d == 28 and e == 6 and a > 10:
        return 418
    march_day = 22 + d + e
    return 300 + march_day if march_day <= 31 else 400 + march_day - 31
