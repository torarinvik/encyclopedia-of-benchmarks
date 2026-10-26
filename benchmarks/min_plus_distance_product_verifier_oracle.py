"""Independent column-oriented verifier for the distance product."""

INF = 1_000_000
MAX_INPUT_LENGTH = 130
MAX_OUTPUT_BYTES = 512


def verify(a):
    if a is None or len(a) < 4 or len(a) > 130:
        return -1, b""
    n, m = a[0], a[1]
    if not isinstance(n, int) or n < 1 or n > 8 or not isinstance(m, int) or m < 1 or m > 8:
        return -1, b""
    if len(a) != 2 + 2*n*m:
        return -1, b""
    split = 2+n*m
    rows_a = [a[2+i*m:2+(i+1)*m] for i in range(n)]
    rows_b = [a[split+i*n:split+(i+1)*n] for i in range(m)]
    if any(not isinstance(x,int) or x < 0 or (x > 1000 and x != INF) for row in rows_a+rows_b for x in row):
        return -1, b""
    answer = []
    for row in rows_a:
        for j in range(n):
            candidates = []
            for k, left in enumerate(row):
                right = rows_b[k][j]
                if left != INF and right != INF:
                    candidates.append(left+right)
            answer.append(min(candidates) if candidates else INF)
    raw = b"".join(x.to_bytes(8,"little",signed=True) for x in answer)
    return len(raw), raw
