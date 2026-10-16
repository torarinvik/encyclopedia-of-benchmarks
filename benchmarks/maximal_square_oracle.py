"""Oracle for bounded flattened binary-matrix maximal-square area."""
INVALID_RESULT=-1
MAX_ROWS=16
MAX_COLS=16
MAX_INPUT_LENGTH=MAX_ROWS*MAX_COLS+2

def expected_result(values):
    if not isinstance(values,(tuple,list)) or len(values)<3 or len(values)>MAX_INPUT_LENGTH: return INVALID_RESULT
    if any(type(v) is not int or not -(2**63)<=v<2**63 for v in values): return INVALID_RESULT
    rows,cols,*cells=values
    if not 1<=rows<=MAX_ROWS or not 1<=cols<=MAX_COLS or len(cells)!=rows*cols or any(v not in (0,1) for v in cells): return INVALID_RESULT
    dp=[0]*cols; best=0
    for r in range(rows):
        diagonal=0
        for c in range(cols):
            above=dp[c]
            if cells[r*cols+c]:
                dp[c]=1 if r==0 or c==0 else min(diagonal,dp[c],dp[c-1])+1
                best=max(best,dp[c])
            else: dp[c]=0
            diagonal=above
    return best*best
