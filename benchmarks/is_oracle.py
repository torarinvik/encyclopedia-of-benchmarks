"""Oracle for the pinned Lua uint53 predicate."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=1
INVALID_RESULT=-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=1 or type(values[0]) is not int or not -(1<<63)<=values[0]<(1<<63):return INVALID_RESULT
    n=values[0]
    return int(0<=n<(1<<53))
