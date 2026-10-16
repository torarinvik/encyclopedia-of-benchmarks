"""Fixed-point contract for the pinned 44.1 kHz equal-loudness filter."""
MAX_SAMPLES = 32
MAX_INPUT_LENGTH = MAX_SAMPLES + 1
SAMPLE_LIMIT = 1_000_000
INVALID = -1
Q = 1 << 30
A = [1073741824,-3875279605,7242592440,-9849938776,11019995787,-10310050823,8022431451,-5130046574,2558322377,-874363774,153873500]
B = [60930872,-44894685,-5549718,-9621322,-7681698,30506759,-32060412,22380311,-4826655,8028337,-4488672]
HA = [1089966811,-2146993250,1057516837]
HB = [1073619225,-2147238449,1073619225]

def _trunc_div(numerator, denominator):
    return abs(numerator) // abs(denominator) * (-1 if (numerator < 0) != (denominator < 0) else 1)

def _step(sample, a, b, xhist, yhist):
    acc = b[0] * sample
    for i in range(1, len(a)):
        acc += b[i] * xhist[i - 1] - a[i] * yhist[i - 1]
    output = _trunc_div(acc, a[0])
    xhist[1:] = xhist[:-1]
    yhist[1:] = yhist[:-1]
    xhist[0] = sample
    yhist[0] = output
    return output

def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not values
            or any(type(v) is not int for v in values)):
        return INVALID
    count = values[0]
    if not 0 <= count <= MAX_SAMPLES or len(values) != count + 1:
        return INVALID
    samples = values[1:]
    if any(abs(x) > SAMPLE_LIMIT for x in samples):
        return INVALID
    yh=[0]*10; xh=[0]*10
    bh=[0]*2; ah=[0]*2
    result=0
    for sample in samples:
        mid=_step(sample,A,B,xh,yh)
        result=_step(mid,HA,HB,bh,ah)
    return result
