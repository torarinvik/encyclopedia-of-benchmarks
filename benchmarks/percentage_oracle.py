"""Oracle for Solidity uint256Percentage on bounded unsigned values."""
MAX_INPUT_LENGTH=3
INVALID_RESULT=-1
def expected_result(values):
 if not isinstance(values,(list,tuple)) or len(values)!=3:return INVALID_RESULT
 if any(type(x)is not int for x in values):return INVALID_RESULT
 a,b,dp=values
 if not 1<=a<=100000 or not 1<=b<=100000 or not 1<=dp<=4:return INVALID_RESULT
 scale=10**dp
 product=a*b*scale
 if product<100:return INVALID_RESULT
 return product//100
