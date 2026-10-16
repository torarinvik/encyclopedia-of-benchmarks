"""Deterministic bounded oracle for the source's wrapped traffic automaton."""

MAX_INPUT_LENGTH = 35
MAX_OUTPUT_BYTES = 544


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 4
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    cells, updates, maximum = values[:3]
    if not 2 <= cells <= 32 or not 0 <= updates <= 16 or not 0 <= maximum <= 5 or len(values) != cells + 3:
        return -1, b""
    row = list(values[3:])
    if any(x < -1 or x > 5 for x in row):
        return -1, b""
    rows = [row]
    for _ in range(updates):
        next_speed = [-1] * cells
        for i, speed in enumerate(row):
            if speed != -1:
                distance = 0
                for j in range(i + 1, cells):
                    if row[j] != -1:
                        break
                    distance += 1
                else:
                    for j in range(cells):
                        if row[j] != -1:
                            break
                        distance += 1
                next_speed[i] = min(min(speed + 1, maximum), distance - 1)
        moved = [-1] * cells
        for i, speed in enumerate(next_speed):
            if speed != -1:
                moved[(i + speed) % cells] = speed
        row = moved
        rows.append(row)
    output = bytes(cell + 1 for row in rows for cell in row)
    return len(output), output
