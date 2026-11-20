"""Cut-enumeration reference for the finite dual-decomposition profile."""

from math import gcd

INVALID_RESULT = -1
MAX_PARSEABLE_INPUT_LENGTH = 63
DUAL_OFFSET = 7000


def _decode(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values)):
        return None
    n, m, overlap, rounds = values[:4]
    if (not 3 <= n <= 6 or not 0 <= m <= 10 or not 1 <= overlap <= 3
            or not 1 <= rounds <= 8 or len(values) != 4 + 3 * n + 4 * m):
        return None
    owners = values[4:4 + n]
    if (any(x not in (0, 1, 2) for x in owners)
            or 0 not in owners or 1 not in owners or owners.count(2) != overlap):
        return None
    at = 4 + n
    source_caps = values[at:at + n]
    sink_caps = values[at + n:at + 2 * n]
    at += 2 * n
    if any(x < 0 or x > 6 or x % 2 for x in source_caps + sink_caps):
        return None
    edges = []
    for _ in range(m):
        u, v, uv, vu = values[at:at + 4]
        at += 4
        if (u < 0 or u >= n or v < 0 or v >= n or u == v
                or {owners[u], owners[v]} == {0, 1}
                or any(x < 0 or x > 6 or x % 2 for x in (uv, vu))):
            return None
        edges.append((u, v, uv, vu))
    return n, overlap, rounds, owners, source_caps, sink_caps, edges


def _scale(rounds):
    value = 2
    for divisor in range(1, rounds + 1):
        value = value * divisor // gcd(value, divisor)
    return value


def _enumerate_cuts(parsed, side, lambda_scaled, scale):
    n, _, _, owners, source_caps, sink_caps, edges = parsed
    members = [owners[u] in (side, 2) for u in range(n)]
    best_energy = None
    best_mask = -1
    for mask in range(1 << n):
        if any(not members[u] and (mask & (1 << u)) for u in range(n)):
            continue
        energy = 0
        for u in range(n):
            if not members[u]:
                continue
            is_sink_side = bool(mask & (1 << u))
            factor = scale // 2 if owners[u] == 2 else scale
            energy += source_caps[u] * factor if is_sink_side else sink_caps[u] * factor
            if owners[u] == 2:
                energy += (lambda_scaled[u] if side == 0 else -lambda_scaled[u]) * int(is_sink_side)
        for u, v, uv, vu in edges:
            if not members[u] or not members[v]:
                continue
            factor = scale // 2 if owners[u] == 2 and owners[v] == 2 else scale
            u_sink = bool(mask & (1 << u))
            v_sink = bool(mask & (1 << v))
            if not u_sink and v_sink:
                energy += uv * factor
            if u_sink and not v_sink:
                energy += vu * factor
        if best_energy is None or energy < best_energy or (energy == best_energy and mask > best_mask):
            best_energy = energy
            best_mask = mask
    labels = [(best_mask >> u) & 1 for u in range(n)]
    return best_energy, labels


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, _, rounds, owners, _, _, _ = parsed
    scale = _scale(rounds)
    lambda_scaled = [0] * n
    dual_scaled = 0
    agreement = False
    for iteration in range(1, rounds + 1):
        energy_m, labels_m = _enumerate_cuts(parsed, 0, lambda_scaled, scale)
        energy_n, labels_n = _enumerate_cuts(parsed, 1, lambda_scaled, scale)
        dual_scaled = energy_m + energy_n
        agreement = all(labels_m[u] == labels_n[u] for u in range(n) if owners[u] == 2)
        if agreement or iteration == rounds:
            break
        step = scale // iteration
        for u in range(n):
            if owners[u] == 2:
                lambda_scaled[u] += step * (labels_m[u] - labels_n[u])
    return 2 * (dual_scaled + DUAL_OFFSET) + int(agreement)
