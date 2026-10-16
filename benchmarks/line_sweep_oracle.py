from collections.abc import Sequence
MAX_INPUT_LENGTH = 17
INVALID_RESULT = -1.0e300

def expected_result(values: Sequence[int]) -> float:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(v) is not int or not -(1<<63) <= v < (1<<63) for v in values):
        return INVALID_RESULT
    n = values[0]
    if not 0 <= n <= 8 or len(values) != 1 + 2*n:
        return INVALID_RESULT
    endpoints=[]
    for i in range(n):
        start,end=values[1+2*i],values[2+2*i]
        if start < 0 or end < start or end > 20:
            return INVALID_RESULT
        endpoints.append((start,end))
    if not endpoints:
        return 0.0
    line=[0]*(max(end for _,end in endpoints)+2)
    for start,end in endpoints:
        line[start]+=1
        line[end+1]-=1
    current=0
    maximum=0
    for delta in line:
        current+=delta
        maximum=max(maximum,current)
    return 1.0 if maximum>1 else 0.0
