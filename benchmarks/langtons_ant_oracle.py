"""Independent packed-state oracle for bounded Langton's ant."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=1
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=1 or type(values[0]) is not int or not I64_MIN<=values[0]<=I64_MAX:return INVALID_RESULT
    steps=values[0]
    if not 0<=steps<=6:return INVALID_RESULT
    board=[[True]*5 for _ in range(5)];x=y=2;direction=3;dirs=((-1,0),(0,1),(1,0),(0,-1))
    for _ in range(steps):
        direction=(direction+1)%4 if board[x][y] else (direction-1)%4
        dx,dy=dirs[direction];nx,ny=x+dx,y+dy
        if not (0<=nx<5 and 0<=ny<5):return INVALID_RESULT
        board[x][y]=not board[x][y];x,y=nx,ny
    mask=0
    for row in range(5):
        for col in range(5):
            if not board[row][col]:mask|=1<<(row*5+col)
    return mask|((x*5+y)<<25)|(direction<<30)
