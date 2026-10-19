"""Independent bit-at-a-time oracle for the MiBench telecomm CRC-32 kernel."""

MAX_LENGTH = 100_001
INITIAL = 0xFFFFFFFF
POLYNOMIAL = 0xEDB88320


def mibench_telecomm_crc32(values):
    """Return CRC-32 for a sequence of byte-valued integers, or -1 if invalid."""
    if values is None or len(values) > MAX_LENGTH:
        return -1
    crc = INITIAL
    for value in values:
        if isinstance(value, bool) or not isinstance(value, int) or not 0 <= value <= 255:
            return -1
        crc ^= value
        for _ in range(8):
            crc = (crc >> 1) ^ POLYNOMIAL if crc & 1 else crc >> 1
    return crc ^ INITIAL
