"""Pair-intersection reference for integer inradius; unexecuted draft."""
from math import gcd, isqrt


def expected_result(values, input_is_null=False):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or not 1 <= len(values) <= 37
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1
    n = values[0]
    if not 0 <= n <= 12 or len(values) != 1+3*n:
        return -1
    lines = []
    for i in range(n):
        a, b, c = values[1+3*i:4+3*i]
        if not (-15 <= a <= 15 and -15 <= b <= 15 and -128 <= c <= 128):
            return -1
        norm2 = a*a+b*b
        norm = isqrt(norm2)
        if norm == 0 or norm*norm != norm2 or gcd(abs(a), abs(b)) != 1:
            return -1
        lines.append((a,b,c,norm))
    lines.extend(((1,0,256,1),(-1,0,256,1),(0,1,256,1),(0,-1,256,1)))

    def feasible(radius):
        shifted = [(a,b,c-radius*norm) for a,b,c,norm in lines]
        for i, (a,b,c) in enumerate(shifted):
            for u,v,w in shifted[i+1:]:
                den = a*v-u*b
                if den == 0:
                    continue
                x, y = c*v-b*w, a*w-c*u
                if den < 0:
                    den, x, y = -den, -x, -y
                if all(p*x+q*y <= k*den for p,q,k in shifted):
                    return True
        return False

    if not feasible(0):
        return -2
    low, high = 0, 257
    while high-low > 1:
        middle = (low+high)//2
        if feasible(middle):
            low = middle
        else:
            high = middle
    return low
