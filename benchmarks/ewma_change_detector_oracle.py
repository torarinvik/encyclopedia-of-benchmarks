"""Fixed-parameter EWMA control-chart detector contract."""
MAX_SAMPLES = 15
MAX_INPUT_LENGTH = MAX_SAMPLES + 1
SAMPLE_LIMIT = 8
INVALID = -1

def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not values
            or any(type(v) is not int for v in values)):
        return INVALID
    count=values[0]
    if not 0 <= count <= MAX_SAMPLES or len(values) != count+1:
        return INVALID
    samples=values[1:]
    if any(abs(x)>SAMPLE_LIMIT for x in samples):
        return INVALID
    exponent=0
    numerator=0
    packed=0
    for sample in samples:
        exponent+=1
        numerator += sample << (exponent-1)
        signal=0
        if 3*numerator*numerator > (1 << (2*exponent))-1:
            signal=1 if numerator>0 else 2
            exponent=0
            numerator=0
        packed=packed*4+signal
    return packed
