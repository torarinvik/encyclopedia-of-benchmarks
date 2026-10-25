"""Independent fixed-point oracle for Embench EDN lattice synthesis."""
from collections.abc import Sequence
MAX_ORDER = 16
MAX_INPUT_LENGTH = 2 + 2 * MAX_ORDER
MAX_OUTPUT_BYTES = 8 * (MAX_ORDER + 1)

def oracle(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (len(values) < 2 or any(type(x) is not int for x in values)):
        return -1, b""
    n, f = values[:2]
    if not 1 <= n <= MAX_ORDER or not -65536 <= f <= 65535 or len(values) != 2 + 2*n:
        return -1, b""
    b = list(values[2:2+n]); k = list(values[2+n:])
    if any(x < -1024 or x > 1023 for x in b+k):
        return -1, b""
    f -= b[n-1] * k[n-1]
    for i in range(n-2, -1, -1):
        f -= b[i] * k[i]
        b[i+1] = b[i] + ((k[i] * (f >> 16)) >> 16)
    b[0] = f >> 16
    output = b"".join(int(x).to_bytes(8, "little", signed=True) for x in [f, *b])
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
