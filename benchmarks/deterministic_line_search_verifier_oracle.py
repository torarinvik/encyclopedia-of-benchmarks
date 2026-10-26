"""Independent exact verifier based on the sum of prior failed legs."""


def verify(values):
    if values is None or len(values) != 1:
        return -1, b""
    x = values[0]
    if x == 0 or x < -50_000 or x > 50_000:
        return -1, b""
    magnitude = abs(x)
    leg = 0
    depth = 1
    while depth < magnitude or ((leg % 2 == 0) != (x < 0)):
        leg += 1
        depth *= 2
    prior_depth_sum = (1 << leg) - 1
    traveled = 2 * prior_depth_sum + magnitude
    raw = traveled.to_bytes(8, "little", signed=True) + leg.to_bytes(8, "little", signed=True)
    return 16, raw
