"""Bounded oracle for median of two sorted integer arrays."""
INVALID_RESULT=-1e300
MAX_TOTAL=256
MAX_INPUT_LENGTH=MAX_TOTAL+3
VALUE_MIN=-1_000_000
VALUE_MAX=1_000_000

def expected_result(values):
    if not isinstance(values,(tuple,list)) or len(values)<2 or len(values)>MAX_INPUT_LENGTH: return INVALID_RESULT
    if any(type(v) is not int or not -(2**63)<=v<2**63 for v in values): return INVALID_RESULT
    n1,n2,*items=values
    if n1<0 or n2<0 or n1+n2<1 or n1+n2>MAX_TOTAL or len(items)!=n1+n2: return INVALID_RESULT
    if any(v<VALUE_MIN or v>VALUE_MAX for v in items): return INVALID_RESULT
    left=items[:n1];right=items[n1:]
    if left!=sorted(left) or right!=sorted(right): return INVALID_RESULT
    merged=sorted(items);m=len(merged)//2
    return float(merged[m]) if len(merged)%2 else (float(merged[m-1])+float(merged[m]))/2.0
