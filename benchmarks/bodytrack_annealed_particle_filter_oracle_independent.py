"""Independent boundary-scan oracle for the bounded Bodytrack profile."""

import struct

Q = 16_777_216
MAX_BYTES = 32


def _away(n, d):
    sign = -1 if n < 0 else 1
    q, r = divmod(abs(n), d)
    return sign * (q + (1 if 2 * r >= d else 0))


def _parse(values, input_length):
    if not isinstance(values, (tuple, list)) or any(
        type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values
    ):
        return None
    if type(input_length) is not int or input_length != len(values) or not 3 <= input_length <= 318:
        return None
    d, n, layer_count = values[0], values[1], values[2]
    if d not in range(1, 5) or n not in range(2, 17) or layer_count not in range(1, 5):
        return None
    if input_length != 2 + d + 2 * layer_count + n * d + (layer_count - 1) * n * (d + 1):
        return None
    p = 3
    target = tuple(values[p:p + d]); p += d
    anneal = tuple(values[p:p + layer_count]); p += layer_count
    spreads = tuple(values[p:p + layer_count - 1]); p += layer_count - 1
    coords = tuple(tuple(values[p + row * d + axis] for axis in range(d)) for row in range(n)); p += n * d
    draw_count = (layer_count - 1) * n
    draws = tuple(values[p:p + draw_count]); p += draw_count
    shocks = tuple(values[p:])
    if any(x < -10000 or x > 10000 for x in target) or any(not -10000 <= v <= 10000 for row in coords for v in row):
        return None
    if any(x < 1 or x > 8 for x in anneal) or any(x >= y for x, y in zip(anneal, anneal[1:])):
        return None
    if any(x < 0 or x > 2000 for x in spreads) or any(x < y for x, y in zip(spreads, spreads[1:])):
        return None
    if any(x < 0 or x >= Q for x in draws) or any(x < -3000 or x > 3000 for x in shocks):
        return None
    return d, n, layer_count, target, anneal, spreads, coords, draws, shocks


def reference_output(values, capacity=None, output_is_null=False,
                     input_is_null=False, input_length=None):
    if input_is_null:
        return -1, b""
    if input_length is None and isinstance(values, (list, tuple)):
        input_length = len(values)
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    d, n, layer_count, target, anneal, spreads, population, draws, shocks = parsed
    cap = MAX_BYTES if capacity is None else capacity
    if type(output_is_null) is not bool or type(cap) is not int or cap < 0:
        return -2, b""
    if output_is_null or cap < 8 * d:
        return -2, b""

    for stage, exponent in enumerate(anneal):
        scores = []
        for candidate in population:
            residual = 0
            for axis in range(d):
                delta = candidate[axis] - target[axis]
                residual += delta * delta
            likelihood = Q * 100000 // (100000 + residual // 10000)
            score = likelihood
            repeat = exponent - 1
            while repeat:
                score = score * likelihood // Q
                repeat -= 1
            scores.append(score)

        denominator = sum(scores)
        if stage == layer_count - 1:
            coordinates = []
            for axis in range(d):
                numerator = 0
                for candidate, score in zip(population, scores):
                    numerator += candidate[axis] * score
                coordinates.append(_away(numerator, denominator))
            result = b"".join(struct.pack("<q", x) for x in coordinates)
            return len(result), result

        rebuilt = []
        for slot in range(n):
            scaled_draw = draws[stage * n + slot] * denominator
            # Count cumulative boundaries no greater than the draw; this is
            # equivalent to selecting the first cumulative interval above it.
            cumulative = 0
            ancestor = n - 1
            for index, score in enumerate(scores):
                cumulative += score
                if scaled_draw < Q * cumulative:
                    ancestor = index
                    break
            updated = []
            for axis in range(d):
                tape_index = stage * n * d + slot * d + axis
                movement = _away(spreads[stage] * shocks[tape_index], 1000)
                updated.append(max(-10000, min(10000, population[ancestor][axis] + movement)))
            rebuilt.append(tuple(updated))
        population = tuple(rebuilt)
    return -1, b""
