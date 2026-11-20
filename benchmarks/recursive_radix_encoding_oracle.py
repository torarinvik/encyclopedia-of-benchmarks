"""Formatting-based references for the bounded decimal-coded radix results."""


def binary(value):
    return int(format(value, "b")) if 0 <= value <= 1023 else -1


def octal(value):
    return int(format(value, "o")) if 0 <= value <= 295_600_127 else -1
