"""Runtime oracle for two-heap integer medians after each insertion."""
import struct
MAX_INPUT_LENGTH = 257
MAX_VECTOR_LENGTH = 256

def _average_trunc_zero(a: int, b: int) -> int:
    total = a + b
    return total // 2 if total >= 0 else -((-total) // 2)

def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values,list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63)<=x<2**63 for x in values)):
        return -1,b""
    n,*stream=values
    if not 1<=n<=MAX_VECTOR_LENGTH or len(stream)!=n or any(not -1_000_000<=x<=1_000_000 for x in stream):
        return -1,b""
    low=[] # negated max heap
    high=[]
    import heapq
    out=[]
    for x in stream:
        if high and x>high[0]: heapq.heappush(high,x)
        else: heapq.heappush(low,-x)
        if len(low)>len(high)+1: heapq.heappush(high,-heapq.heappop(low))
        elif len(high)>len(low)+1: heapq.heappush(low,-heapq.heappop(high))
        if len(low)==len(high): median=_average_trunc_zero(-low[0],high[0])
        elif len(low)>len(high): median=-low[0]
        else: median=high[0]
        out.append(median)
    encoded=b"".join(struct.pack("<q",x) for x in out)
    return len(encoded),encoded
