"""Layered edit-distance dynamic program over a supplied literal NFA."""

MAX_STATES = 8
MAX_TRANSITIONS = 16
MAX_TEXT = 12
MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = MAX_TEXT


def evaluate(values):
    if values is None or len(values) < 6 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    states, edge_count, text_len, threshold, start, accept = values[:6]
    if not (2 <= states <= MAX_STATES and 1 <= edge_count <= MAX_TRANSITIONS
            and 0 <= text_len <= MAX_TEXT and 0 <= threshold <= 3
            and 0 <= start < states and 0 <= accept < states and start != accept):
        return -1, b""
    edge_start = 6
    text_start = edge_start + 3 * edge_count
    if len(values) != text_start + text_len:
        return -1, b""
    transitions = []
    seen = set()
    for i in range(edge_start, text_start, 3):
        src, dst, label = values[i:i + 3]
        if not (0 <= src < states and 0 <= dst < states and 1 <= label <= 127):
            return -1, b""
        edge = (src, dst, label)
        if edge in seen:
            return -1, b""
        seen.add(edge)
        transitions.append(edge)
    text = values[text_start:]
    if any(not 1 <= c <= 127 for c in text):
        return -1, b""

    inf = threshold + 1
    current = [inf] * states
    output = bytearray()

    def insertion_closure(costs):
        # Every same-layer edge costs one, so a shortest useful path is simple.
        for _ in range(states - 1):
            changed = False
            for src, dst, _label in transitions:
                candidate = min(inf, costs[src] + 1)
                if candidate < costs[dst]:
                    costs[dst] = candidate
                    changed = True
            if not changed:
                break

    for char in text:
        current[start] = 0  # begin a candidate nonempty substring here
        insertion_closure(current)
        nxt = [min(inf, cost + 1) for cost in current]  # delete this text byte
        for src, dst, label in transitions:
            candidate = current[src] + (label != char)
            if candidate < nxt[dst]:
                nxt[dst] = candidate
        insertion_closure(nxt)
        output.append(1 if nxt[accept] <= threshold else 0)
        current = nxt
    return len(output), bytes(output)
