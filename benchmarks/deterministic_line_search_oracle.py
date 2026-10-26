"""Primary simulator for deterministic alternating-ray doubling search."""

MAX_ABS_TARGET = 50_000
MAX_INPUT_LENGTH = 1
MAX_OUTPUT_BYTES = 16


def evaluate(values):
    if values is None or len(values) != 1:
        return -1, b""
    target = values[0]
    if target == 0 or abs(target) > MAX_ABS_TARGET:
        return -1, b""
    distance = abs(target)
    traveled = 0
    leg = 0
    depth = 1
    while True:
        negative_ray = leg % 2 == 0
        target_on_ray = (target < 0) == negative_ray
        if target_on_ray and distance <= depth:
            traveled += distance
            result = (traveled, leg)
            return 16, b"".join(x.to_bytes(8, "little", signed=True) for x in result)
        traveled += 2 * depth
        leg += 1
        depth *= 2
