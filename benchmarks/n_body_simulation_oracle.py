"""Runtime oracle for bounded deterministic softened N-body Euler steps."""
import math
import struct

MAX_INPUT_LENGTH = 26
MAX_OUTPUT_BYTES = 128


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 6
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    count, steps, dt_milli, gravity_milli, time_factor, softening_milli = values[:6]
    if (not 2 <= count <= 4 or not 0 <= steps <= 4 or not 1 <= dt_milli <= 1000
            or not 0 <= gravity_milli <= 1000 or not 1 <= time_factor <= 10
            or not 1 <= softening_milli <= 3000 or len(values) != 6 + 5 * count):
        return -1, b""
    bodies = []
    for i in range(count):
        x, y, vx, vy, mass = values[6 + 5*i:11 + 5*i]
        if (not -1000 <= x <= 1000 or not -1000 <= y <= 1000
                or not -100 <= vx <= 100 or not -100 <= vy <= 100
                or not 1 <= mass <= 1000):
            return -1, b""
        bodies.append([float(x), float(y), float(vx), float(vy), float(mass)])
    dt = (dt_milli / 1000.0) * time_factor
    gravity = gravity_milli / 1000.0
    softening = softening_milli / 1000.0
    for _ in range(steps):
        for i, body in enumerate(bodies):
            force_x = force_y = 0.0
            for j, other in enumerate(bodies):
                if i == j:
                    continue
                dx = other[0] - body[0]
                dy = other[1] - body[1]
                distance = (dx**2 + dy**2 + softening) ** (1 / 2)
                force_x += gravity * other[4] * dx / distance**3
                force_y += gravity * other[4] * dy / distance**3
            body[2] += force_x * dt
            body[3] += force_y * dt
        for body in bodies:
            body[0] += body[2] * dt
            body[1] += body[3] * dt
    output = [component for body in bodies for component in body[:4]]
    payload = struct.pack("<" + "d" * len(output), *output)
    return len(payload), payload
