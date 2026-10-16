"""Oracle for nPr using the pinned factorial ratio."""
MAX_INPUT_LENGTH=2
INVALID_RESULT=-1
def _factorial(n):
 result=1
 for i in range(1,n+1):result*=i
 return result
def expected_result(values):
 if not isinstance(values,(list,tuple)) or len(values)!=2:return INVALID_RESULT
 if any(type(x)is not int for x in values):return INVALID_RESULT
 n,r=values
 if not 0<=n<=15 or not 0<=r<=n:return INVALID_RESULT
 return _factorial(n)//_factorial(n-r)
