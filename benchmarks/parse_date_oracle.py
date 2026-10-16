"""Runtime oracle for the pinned dd/mm/yyyy parser."""

MAX_INPUT_LENGTH = 11


def expected_result(values: list[int]) -> int:
    if (len(values) < 9 or len(values) > MAX_INPUT_LENGTH
            or type(values[0]) is not int or not 8 <= values[0] <= 10
            or len(values) != values[0] + 1
            or any(type(byte) is not int or not 0 <= byte <= 127 for byte in values[1:])):
        return -1
    try:
        text = bytes(values[1:]).decode("ascii")
    except UnicodeDecodeError:
        return -1
    parts = text.split("/")
    if (len(parts) != 3 or not 1 <= len(parts[0]) <= 2
            or not 1 <= len(parts[1]) <= 2 or len(parts[2]) != 4
            or any(not part.isascii() or not part.isdigit() for part in parts)):
        return -1
    day, month, year = map(int, parts)
    if not 1 <= month <= 12:
        return -1
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if month == 2 and year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
        days[1] = 29
    if not 1 <= day <= days[month - 1]:
        return -1
    return year * 10_000 + month * 100 + day
