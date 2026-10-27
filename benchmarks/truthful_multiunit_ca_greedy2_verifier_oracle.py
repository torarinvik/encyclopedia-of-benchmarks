"""Independent direct-log verifier oracle for Greedy-2."""
from __future__ import annotations

from collections.abc import Sequence
import math


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 5 or len(values) > 32
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    items, bidders = values[0], values[1]
    if not 2 <= items <= 6 or not 1 <= bidders <= 12 or len(values) != 2 + items + 2*bidders:
        return -1, b""
    caps = values[2:2+items]
    if any(not 1 <= cap <= 8 for cap in caps):
        return -1, b""
    bids = []
    for j in range(bidders):
        value, mask = values[2+items+2*j:4+items+2*j]
        if not 1 <= value <= 100 or not 1 <= mask < (1 << items):
            return -1, b""
        bids.append((value, mask))
    # Recompute e^B as exp(B log(e)), then each root as exp(log(T)/b_e).
    base_e = math.exp(math.log(2.718281828459045))
    threshold = math.exp(min(caps) * math.log(base_e)) * items
    prices = [1.0 / cap for cap in caps]
    live = [True] * bidders
    chosen = []
    while any(live):
        winner = -1
        numerator = -1.0
        for j, (value, mask) in enumerate(bids):
            if not live[j]:
                continue
            denominator = 0.0
            for e in range(items):
                if mask & (1 << e):
                    denominator += prices[e]
            score = value / denominator
            if winner < 0 or score > numerator:
                winner, numerator = j, score
        if winner < 0:
            break
        live[winner] = False
        chosen.append(winner)
        mask = bids[winner][1]
        for e in range(items):
            if mask & (1 << e):
                prices[e] *= math.exp(math.log(threshold) / caps[e])
        dual = 0.0
        for e in range(items):
            dual += caps[e] * prices[e]
        if dual >= threshold:
            break
    result = [len(chosen), *chosen]
    payload = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
