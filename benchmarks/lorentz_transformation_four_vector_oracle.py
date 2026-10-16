from collections.abc import Sequence
from math import sqrt
MAX_INPUT_LENGTH = 6
INVALID_RESULT = -1.0e300
C = 299_792_458

def expected_result(values: Sequence[int]) -> float:
    if not isinstance(values, (list, tuple)) or len(values) != 6:
        return INVALID_RESULT
    if any(type(v) is not int or not -(1<<63) <= v < (1<<63) for v in values):
        return INVALID_RESULT
    velocity, component, time_us, x_cm, y_cm, z_cm = values
    if not (1 <= velocity <= 200_000_000 and 0 <= component <= 3):
        return INVALID_RESULT
    if not (-1_000_000 <= time_us <= 1_000_000 and all(-100_000_000 <= x <= 100_000_000 for x in (x_cm, y_cm, z_cm))):
        return INVALID_RESULT
    beta = velocity / C
    gamma = 1 / sqrt(1 - beta**2)
    event = [time_us / 1_000_000, x_cm / 100, y_cm / 100, z_cm / 100]
    event[0] *= C
    transformed = [gamma*event[0] - gamma*beta*event[1], -gamma*beta*event[0] + gamma*event[1], event[2], event[3]]
    return transformed[component]
