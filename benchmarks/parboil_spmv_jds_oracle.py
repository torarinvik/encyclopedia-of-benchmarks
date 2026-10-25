"""Independent binary32 oracle for the bounded Parboil JDS SpMV profile."""
import math
import struct

MAX_DIMENSION = 8
MAX_INPUT_LENGTH = 164
MAX_PARSEABLE_INPUT_LENGTH = 165
MAX_OUTPUT_BYTES = 36
INVALID_RESULT = -1
OUTPUT_ERROR = -2

def _f32(x):
    return struct.unpack('<f', struct.pack('<f', float(x)))[0]

def expected_output(values):
    if values is None or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b''
    n, depth, nnz = values[:3]
    if not (1 <= n <= 8 and 1 <= depth <= 8 and 1 <= nnz <= n * depth):
        return INVALID_RESULT, b''
    expected_len = 4 + 3*n + depth + 2*nnz
    if len(values) != expected_len:
        return INVALID_RESULT, b''
    p = 3
    rows = values[p:p+n]; p += n
    perm = values[p:p+n]; p += n
    ptr = values[p:p+depth+1]; p += depth+1
    cols = values[p:p+nnz]; p += nnz
    data = values[p:p+nnz]; p += nnz
    vector = values[p:p+n]
    if any(type(x) is not int for x in values): return INVALID_RESULT, b''
    if any(not 0 <= x <= depth for x in rows) or rows[0] != depth:
        return INVALID_RESULT, b''
    if any(rows[i] < rows[i+1] for i in range(n-1)) or sum(rows) != nnz:
        return INVALID_RESULT, b''
    lengths = [sum(1 for r in rows if r > k) for k in range(depth)]
    want = [0]
    for x in lengths: want.append(want[-1] + x)
    if ptr != want or ptr[-1] != nnz: return INVALID_RESULT, b''
    if sorted(perm) != list(range(n)): return INVALID_RESULT, b''
    if any(c < 0 or c >= n for c in cols): return INVALID_RESULT, b''
    if any(v < -1_000_000 or v > 1_000_000 for v in data+vector):
        return INVALID_RESULT, b''
    x = [_f32(_f32(v) / _f32(1_000_000)) for v in vector]
    y = [0.0] * n
    for i in range(n):
        acc = _f32(0)
        for k in range(rows[i]):
            j = ptr[k] + i
            product = _f32(_f32(data[j]) / _f32(1_000_000))
            product = _f32(product * x[cols[j]])
            acc = _f32(acc + product)
        y[perm[i]] = acc
    return n*4+4, struct.pack('<I', n) + b''.join(struct.pack('<f', v) for v in y)

oracle = expected_output
