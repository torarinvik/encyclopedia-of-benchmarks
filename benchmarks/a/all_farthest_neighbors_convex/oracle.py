"""Direct reference for convex-polygon farthest-neighbor draft."""

def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 7
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    n = values[0]
    if not 3 <= n <= 64 or len(values) != 1+2*n: return -1, b""
    points = list(zip(values[1::2], values[2::2]))
    if any(abs(x) > 1_000_000 or abs(y) > 1_000_000 for x, y in points): return -1, b""
    for i in range(n):
        a, b, c = points[i], points[(i+1)%n], points[(i+2)%n]
        if (b[0]-a[0])*(c[1]-b[1])-(b[1]-a[1])*(c[0]-b[0]) >= 0: return -1, b""
    answer = []
    for i, (x, y) in enumerate(points):
        def distance(step):
            a, b = points[(i+step)%n]
            return (x-a)**2+(y-b)**2
        best = max(range(1,n), key=distance)
        answer.append((i+best)%n)
    if output_is_null or (capacity is not None and capacity < 8*n): return -2, b""
    return 8*n, b"".join(index.to_bytes(8,"little",signed=True) for index in answer)
