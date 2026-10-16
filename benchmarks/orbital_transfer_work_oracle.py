"""Runtime oracle for the bounded orbital-transfer work calculation."""
import struct

MAX_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 8
G = 6.67430e-11


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 4
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    central_mass, object_mass, initial_radius, final_radius = values
    if (not -1_000_000_000 <= central_mass <= 1_000_000_000
            or not -1_000_000 <= object_mass <= 1_000_000
            or not 1 <= initial_radius <= 1_000_000_000
            or not 1 <= final_radius <= 1_000_000_000):
        return -1, b""
    work = (G * central_mass * object_mass / 2.0) * (1.0 / initial_radius - 1.0 / final_radius)
    payload = struct.pack("<d", work)
    return 8, payload
