"""Runtime oracle for the pinned Java P² median estimator on bounded streams."""
MAX_SAMPLES = 64
MAX_INPUT_LENGTH = 1 + MAX_SAMPLES
INVALID_RESULT = -1e300


def expected_result(values):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(x) is not int for x in values):
        return INVALID_RESULT
    count = values[0]
    samples = values[1:]
    if not 1 <= count <= MAX_SAMPLES or len(samples) != count:
        return INVALID_RESULT
    if any(not -(1 << 31) <= x < (1 << 31) for x in samples):
        return INVALID_RESULT
    heights = [0.0] * 5
    positions = [0] * 5
    desired = [0.0] * 5
    increments = [0.0, 0.25, 0.5, 0.75, 1.0]
    seen = 0
    for raw in samples:
        value = float(raw)
        if seen < 5:
            heights[seen] = value
            seen += 1
            if seen == 5:
                heights.sort()
                positions[:] = [1, 2, 3, 4, 5]
                desired[:] = [1.0, 2.0, 3.0, 4.0, 5.0]
            continue
        if value < heights[0]:
            heights[0] = value
            cell = 0
        else:
            cell = 3
            for i in range(1, 4):
                if value < heights[i]:
                    cell = i - 1
                    break
            if value > heights[4]:
                heights[4] = value
        for i in range(cell + 1, 5):
            positions[i] += 1
        for i in range(5):
            desired[i] += increments[i]
        for i in range(1, 4):
            drift = desired[i] - positions[i]
            right = drift >= 1.0 and positions[i + 1] - positions[i] > 1
            left = drift <= -1.0 and positions[i - 1] - positions[i] < -1
            if not right and not left:
                continue
            direction = 1 if right else -1
            span_left = positions[i] - positions[i - 1]
            span_right = positions[i + 1] - positions[i]
            candidate = heights[i] + direction / (span_left + span_right) * (
                (span_left + direction) * (heights[i + 1] - heights[i]) / span_right
                + (span_right - direction) * (heights[i] - heights[i - 1]) / span_left
            )
            if heights[i - 1] < candidate < heights[i + 1]:
                heights[i] = candidate
            else:
                neighbor = i + direction
                heights[i] += direction * (heights[neighbor] - heights[i]) / (positions[neighbor] - positions[i])
            positions[i] += direction
    if seen < 5:
        ordered = sorted(float(x) for x in samples)
        rank = 0.5 * (len(ordered) - 1)
        lower = int(rank)
        upper = min(lower + 1, len(ordered) - 1)
        return ordered[lower] + (rank - lower) * (ordered[upper] - ordered[lower])
    return heights[2]
