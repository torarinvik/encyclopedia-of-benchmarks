"""Independent oracle for bounded Lee grid BFS."""
from collections import deque
from collections.abc import Sequence
MAX_INPUT_LENGTH=70
INVALID_RESULT=-2
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)<6 or len(values)>MAX_INPUT_LENGTH:return INVALID_RESULT
    if any(type(x) is not int for x in values):return INVALID_RESULT
    rows,cols,sr,sc,dr,dc=values[:6]
    if not 1<=rows<=8 or not 1<=cols<=8 or len(values)!=6+rows*cols:return INVALID_RESULT
    if not (0<=sr<rows and 0<=dr<rows and 0<=sc<cols and 0<=dc<cols):return INVALID_RESULT
    cells=values[6:]
    if any(x not in (0,1) for x in cells):return INVALID_RESULT
    if cells[sr*cols+sc]!=1 or cells[dr*cols+dc]!=1:return -1
    dist=[-1]*(rows*cols);start=sr*cols+sc;goal=dr*cols+dc;dist[start]=0;q=deque([start])
    while q:
        u=q.popleft()
        if u==goal:return dist[u]
        r,c=divmod(u,cols)
        for rr,cc in ((r-1,c),(r,c-1),(r,c+1),(r+1,c)):
            if 0<=rr<rows and 0<=cc<cols:
                v=rr*cols+cc
                if cells[v]==1 and dist[v]<0:dist[v]=dist[u]+1;q.append(v)
    return -1
