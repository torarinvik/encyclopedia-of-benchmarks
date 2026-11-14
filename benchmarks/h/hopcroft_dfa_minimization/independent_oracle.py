"""Direct repeated-signature refinement for small DFA instances."""

def expected(values):
    if values is None or len(values) < 2:
        return -1
    n, alphabet = values[:2]
    if not 1 <= n <= 4096 or not 1 <= alphabet <= 4 or len(values) != 2 + n + n * alphabet:
        return -1
    flags = values[2:2+n]
    transitions = values[2+n:]
    if any(x not in (0, 1) for x in flags) or any(not 0 <= x < n for x in transitions):
        return -1
    classes = list(flags)
    while True:
        signatures = [(classes[s], *(classes[transitions[s * alphabet + c]] for c in range(alphabet)))
                      for s in range(n)]
        ids = {}
        refined = [ids.setdefault(signature, len(ids)) for signature in signatures]
        if len(set(refined)) == len(set(classes)):
            return len(ids)
        classes = refined
