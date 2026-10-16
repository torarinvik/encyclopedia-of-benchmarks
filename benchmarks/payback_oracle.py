"""Oracle for the cumulative cash-flow payback scan."""
MAX_INPUT_LENGTH=129
INVALID_RESULT=-2
def expected_result(values):
 if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH:return INVALID_RESULT
 if any(type(x)is not int for x in values):return INVALID_RESULT
 n=values[0]
 if not 0<=n<=128 or len(values)!=n+1 or any(abs(x)>1_000_000 for x in values[1:]):return INVALID_RESULT
 total=0
 for year,flow in enumerate(values[1:]):
  total+=flow
  if total>=0:return year
 return -1
