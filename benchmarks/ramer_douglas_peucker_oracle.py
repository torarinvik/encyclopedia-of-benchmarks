"""Oracle for the common bounded Python/Rust RDP behavior."""

from __future__ import annotations

from collections.abc import Sequence
import math

MAX_POINTS = 12
MAX_ABS_COORDINATE = 100.0
MAX_EPSILON = 100.0
MAX_INPUT_LENGTH = 2 + 2 * MAX_POINTS
MAX_OUTPUT_LENGTH = 1 + 2 * MAX_POINTS
INVALID_RESULT = -1


def _valid_projection_domain(points: list[tuple[float, float]], epsilon: float) -> bool:
    """Check the common geometry and matching split decisions on every chord."""
    if len(points) < 3:
        return True
    if len(set(points)) != len(points):
        return False
    for i in range(len(points) - 2):
        ax, ay = points[i]
        for j in range(i + 2, len(points)):
            bx, by = points[j]
            dx, dy = bx - ax, by - ay
            length_squared = dx * dx + dy * dy
            # Rust Point::euclidean_distance uses sqrt(dx*dx + dy*dy), not hypot.
            line_length = math.sqrt(length_squared) if length_squared >= 0.0 else math.nan
            if not math.isfinite(length_squared) or length_squared <= 0.0:
                return False
            if not math.isfinite(line_length) or line_length <= 0.0:
                return False
            max_clamped = 0.0
            max_line = 0.0
            index_clamped = i
            index_line = i
            for k in range(i + 1, j):
                px, py = points[k]
                t = ((px - ax) * dx + (py - ay) * dy) / length_squared
                if not 0.0 <= t <= 1.0:
                    return False
                nearest_x = ax + t * dx
                nearest_y = ay + t * dy
                clamped_distance = math.hypot(px - nearest_x, py - nearest_y)
                numerator = dy * px - dx * py + bx * ay - by * ax
                line_distance = abs(numerator) / line_length
                if not math.isfinite(clamped_distance) or not math.isfinite(line_distance):
                    return False
                if clamped_distance > max_clamped:
                    max_clamped = clamped_distance
                    index_clamped = k
                if line_distance > max_line:
                    max_line = line_distance
                    index_line = k
            if index_clamped != index_line or (max_clamped > epsilon) != (max_line > epsilon):
                return False
    return True


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def expected_result(values: Sequence[int | float] | None) -> list[float] | int:
    """Return count followed by retained coordinates, or -1 for invalid input."""
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if not all(_finite_number(value) for value in values):
        return INVALID_RESULT
    if values[0] != int(values[0]):
        return INVALID_RESULT
    count = int(values[0])
    epsilon = float(values[1])
    if not 0 <= count <= MAX_POINTS or len(values) != 2 + 2 * count:
        return INVALID_RESULT
    if not 0.0 <= epsilon <= MAX_EPSILON:
        return INVALID_RESULT
    coords = [float(value) for value in values[2:]]
    if any(abs(value) > MAX_ABS_COORDINATE for value in coords):
        return INVALID_RESULT
    points = [(coords[2 * i], coords[2 * i + 1]) for i in range(count)]
    if not _valid_projection_domain(points, epsilon):
        return INVALID_RESULT
    if count < 3:
        keep = list(range(count))
    else:
        keep_flags = [False] * count
        keep_flags[0] = keep_flags[-1] = True
        pending = [(0, count - 1)]
        while pending:
            start, end = pending.pop()
            max_distance = 0.0
            max_index = start
            ax, ay = points[start]
            bx, by = points[end]
            dx, dy = bx - ax, by - ay
            length = math.hypot(dx, dy)
            for index in range(start + 1, end):
                px, py = points[index]
                # Match Python's pinned clamped projection and nearest point.
                t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
                nearest_x = ax + t * dx
                nearest_y = ay + t * dy
                distance = math.hypot(px - nearest_x, py - nearest_y)
                if distance > max_distance:
                    max_distance = distance
                    max_index = index
            if max_distance > epsilon:
                keep_flags[max_index] = True
                pending.append((start, max_index))
                pending.append((max_index, end))
        keep = [i for i, retained in enumerate(keep_flags) if retained]
    output: list[float] = [float(len(keep))]
    for i in keep:
        output.extend(points[i])
    return output
