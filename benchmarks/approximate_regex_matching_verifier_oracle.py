"""Independent 0-1 shortest-path verifier over automaton/text product states."""
from collections import deque


def verify(values):
    if values is None or len(values) < 6 or len(values) > 66:
        return -1, b""
    states, edge_count, text_len, threshold, start, accept = values[:6]
    if not (2 <= states <= 8 and 1 <= edge_count <= 16 and 0 <= text_len <= 12
            and 0 <= threshold <= 3 and 0 <= start < states
            and 0 <= accept < states and start != accept):
        return -1, b""
    edge_start = 6
    text_start = edge_start + 3 * edge_count
    if len(values) != text_start + text_len:
        return -1, b""
    outgoing = [[] for _ in range(states)]
    seen = set()
    for i in range(edge_start, text_start, 3):
        src, dst, label = values[i:i + 3]
        if not (0 <= src < states and 0 <= dst < states and 1 <= label <= 127):
            return -1, b""
        if (src, dst, label) in seen:
            return -1, b""
        seen.add((src, dst, label))
        outgoing[src].append((dst, label))
    text = values[text_start:]
    if any(not 1 <= c <= 127 for c in text):
        return -1, b""

    result = bytearray(text_len)
    inf = threshold + 1
    # Independently solve each possible nonempty substring start with 0-1 BFS.
    for begin in range(text_len):
        dist = [[inf] * (text_len + 1) for _ in range(states)]
        dist[start][begin] = 0
        queue = deque([(start, begin)])
        while queue:
            state, pos = queue.popleft()
            base = dist[state][pos]
            if base > threshold:
                continue
            # Insert a regex character without consuming text.
            for dst, _label in outgoing[state]:
                if base + 1 < dist[dst][pos]:
                    dist[dst][pos] = base + 1
                    queue.append((dst, pos))
            if pos == text_len:
                continue
            # Delete this text character.
            if base + 1 < dist[state][pos + 1]:
                dist[state][pos + 1] = base + 1
                queue.append((state, pos + 1))
            # Match or substitute while advancing in both automaton and text.
            for dst, label in outgoing[state]:
                cost = int(label != text[pos])
                if base + cost < dist[dst][pos + 1]:
                    dist[dst][pos + 1] = base + cost
                    if cost == 0:
                        queue.appendleft((dst, pos + 1))
                    else:
                        queue.append((dst, pos + 1))
        for end in range(begin + 1, text_len + 1):
            if dist[accept][end] <= threshold:
                result[end - 1] = 1
    return text_len, bytes(result)
