"""Independent Python oracle for the bounded Rodinia LavaMD interaction kernel."""

import math

SCALE = 1_000_000.0
BIAS = 1_000_000_000_000
MAX_PARTICLES = 4
MAX_COMPONENT_RAW = 1_000_000
MIN_INPUT_LENGTH = 12
MAX_INPUT_LENGTH = 2 + 10 * MAX_PARTICLES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1


def _round_away(value):
    scaled = value * SCALE
    if scaled < 0:
        return -math.floor(-scaled + 0.5)
    return math.floor(scaled + 0.5)


def rodinia_lavamd(values):
    if (not isinstance(values, (list, tuple))
            or len(values) < MIN_INPUT_LENGTH or len(values) > MAX_INPUT_LENGTH):
        return -1
    home_count, neighbor_count = values[:2]
    if any(not isinstance(x, int) or isinstance(x, bool) for x in (home_count, neighbor_count)):
        return -1
    if not (1 <= home_count <= MAX_PARTICLES and 1 <= neighbor_count <= MAX_PARTICLES):
        return -1
    if len(values) != 2 + 5 * (home_count + neighbor_count):
        return -1
    cursor = 2
    boxes = []
    for count in (home_count, neighbor_count):
        particles = []
        for _ in range(count):
            raw = values[cursor:cursor + 5]
            cursor += 5
            if any(not isinstance(x, int) or isinstance(x, bool) or not 0 <= x <= MAX_COMPONENT_RAW for x in raw):
                return -1
            particles.append(tuple(float(x) / SCALE for x in raw))
        boxes.append(particles)

    total = 0.0
    for i, a in enumerate(boxes[0]):
        force_v = force_x = force_y = force_z = 0.0
        # Source order is the home box first, followed by its neighbor list.
        for particles in boxes:
            for b in particles:
                dot = a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
                r2 = a[0] + b[0] - dot
                vij = math.exp(-(0.5 * r2))
                fs = 2.0 * vij
                dx = a[1] - b[1]
                dy = a[2] - b[2]
                dz = a[3] - b[3]
                force_v += b[4] * vij
                force_x += b[4] * (fs * dx)
                force_y += b[4] * (fs * dy)
                force_z += b[4] * (fs * dz)
        total += float(i + 1) * ((force_v + force_x) + force_y + force_z)
    return BIAS + _round_away(total)
