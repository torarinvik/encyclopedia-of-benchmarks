"""Pinned-spigot oracle for the bounded decimal-digit generator."""
MAX_DIGITS = 8
INVALID_RESULT = -1

def pi_text(digits: int) -> str:
    q, r, t, k, n, m = 1, 0, 1, 1, 3, 3
    counter = 0
    result = ""
    while counter != digits + 1:
        if 4 * q + r - t < n * t:
            result += str(n)
            if counter == 0:
                result += "."
            if digits == counter:
                break
            counter += 1
            nr = 10 * (r - n * t)
            n = (10 * (3 * q + r) // t) - 10 * n
            q *= 10
            r = nr
        else:
            nr = (2 * q + r) * m
            nn = (q * (7 * k) + 2 + (r * m)) // (t * m)
            q *= k
            t *= m
            m += 2
            k += 1
            n = nn
            r = nr
    return result

def expected_result(digits: int) -> int:
    if type(digits) is not int or not 0 <= digits <= MAX_DIGITS:
        return INVALID_RESULT
    h = 2166136261
    for b in pi_text(digits).encode("ascii"):
        h = ((h ^ b) * 16777619) & 0xFFFFFFFF
    return h
