"""Binary32 Newton-Raphson oracle for the real sqrt(3) specialization."""
import math
import struct
INVALID_RESULT = -1e300

def f32(x):
    return struct.unpack('<f', struct.pack('<f', x))[0]

def expected_result(x: float) -> float:
    if not math.isfinite(x) or not 1.0 <= x <= 4.0:
        return INVALID_RESULT
    guess = f32(x)
    for _ in range(1000):
        residual = f32(f32(guess * guess) - f32(3.0))
        if abs(residual) <= 1e-6:
            return float(guess)
        derivative = f32(f32(2.0) * guess)
        if derivative == 0.0:
            return INVALID_RESULT
        guess = f32(guess - f32(residual / derivative))
    return float(guess)
