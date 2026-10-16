"""Oracle for the source's max-heap minimum-deviation loop."""
import heapq
MAX_INPUT_LENGTH=65
def expected_result(values):
    if not isinstance(values,(list,tuple)) or not 2<=len(values)<=MAX_INPUT_LENGTH:return -1
    if any(type(x)is not int or not -(2**63)<=x<2**63 for x in values):return -1
    n=values[0]
    if not 1<=n<=64 or len(values)!=n+1:return -1
    nums=values[1:]
    if any(not 1<=x<=1_000_000 for x in nums):return -1
    heap=[-(x*2 if x%2 else x) for x in nums];heapq.heapify(heap)
    low=min(-x for x in heap);best=-heap[0]-low
    while heap and heap[0]%2==0:
        x=-heapq.heappop(heap)//2;heapq.heappush(heap,-x);low=min(low,x);best=min(best,-heap[0]-low)
    return best
