"""Direct-array reference oracle for the bounded Bodytrack profile."""

import struct

MAX_INPUT = 318
Q24 = 1 << 24
MAX_BYTES = 32
MAX_D, MAX_N, MAX_L = 4, 16, 4


def _round_away(numerator, denominator):
    magnitude = abs(numerator)
    quotient, remainder = divmod(magnitude, denominator)
    if 2 * remainder >= denominator:
        quotient += 1
    return -quotient if numerator < 0 else quotient


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 3
            or input_length > MAX_INPUT or input_length != len(values)
            or any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
                   for value in values)):
        return -1, b""

    d, n, layers = values[:3]
    if not (1 <= d <= MAX_D and 2 <= n <= MAX_N and 1 <= layers <= MAX_L):
        return -1, b""
    needed = 2 + d + 2 * layers + n * d + (layers - 1) * n * (d + 1)
    if input_length != needed:
        return -1, b""

    cursor = 3
    target = values[cursor:cursor + d]
    cursor += d
    beta = values[cursor:cursor + layers]
    cursor += layers
    sigma = values[cursor:cursor + layers - 1]
    cursor += layers - 1
    if any(not -10000 <= x <= 10000 for x in target):
        return -1, b""
    if any(not 1 <= x <= 8 for x in beta) or any(a >= b for a, b in zip(beta, beta[1:])):
        return -1, b""
    if any(not 0 <= x <= 2000 for x in sigma) or any(a < b for a, b in zip(sigma, sigma[1:])):
        return -1, b""

    flat_pose = values[cursor:cursor + n * d]
    cursor += n * d
    if any(not -10000 <= x <= 10000 for x in flat_pose):
        return -1, b""
    particles = [list(flat_pose[i * d:(i + 1) * d]) for i in range(n)]
    transitions = (layers - 1) * n
    uniforms = values[cursor:cursor + transitions]
    cursor += transitions
    shocks = values[cursor:]
    if any(not 0 <= u < Q24 for u in uniforms):
        return -1, b""
    if any(not -3000 <= z <= 3000 for z in shocks):
        return -1, b""

    effective_capacity = MAX_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < d * 8:
        return -2, b""

    for layer in range(layers):
        weights = []
        for pose in particles:
            squared = sum((pose[axis] - target[axis]) ** 2 for axis in range(d))
            energy = squared // 10000
            base = (Q24 * 100000) // (100000 + energy)
            weight = base
            for _ in range(1, beta[layer]):
                weight = (weight * base) // Q24
            weights.append(weight)

        if layer + 1 == layers:
            total = sum(weights)
            answer = []
            for axis in range(d):
                moment = sum(weights[i] * particles[i][axis] for i in range(n))
                answer.append(_round_away(moment, total))
            encoded = b"".join(struct.pack("<q", coordinate) for coordinate in answer)
            return len(encoded), encoded

        total = sum(weights)
        first_uniform = layer * n
        first_shock = layer * n * d
        next_particles = []
        for child in range(n):
            threshold = (uniforms[first_uniform + child] * total) // Q24
            cumulative = 0
            ancestor = 0
            while cumulative <= threshold:
                cumulative += weights[ancestor]
                if cumulative <= threshold:
                    ancestor += 1
            parent = particles[ancestor]
            child_pose = []
            for axis in range(d):
                shock = shocks[first_shock + child * d + axis]
                offset = _round_away(sigma[layer] * shock, 1000)
                child_pose.append(max(-10000, min(10000, parent[axis] + offset)))
            next_particles.append(child_pose)
        particles = next_particles
    raise AssertionError("positive layer count always reaches the final estimate")
