from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime DR:InlineArray[Int64,8]=[2,1,-1,-2,-2,-1,1,2]
comptime DC:InlineArray[Int64,8]=[1,2,2,1,-1,-2,-2,-1]
fn kt_dfs(mut board:InlineArray[Int64,64],row:Int,col:Int,step:Int)->Bool:
    if step==64:return True
    for m in range(8):
        let r=row+Int(DR[m]);let c=col+Int(DC[m])
        if r>=0 and r<8 and c>=0 and c<8 and board[r*8+c]==-1:
            board[r*8+c]=step
            if kt_dfs(board,r,c,step+1):return True
            board[r*8+c]=-1
    return False
@export("knight_tour_open_dfs")
fn knight_tour_open_dfs(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n!=0:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<512:return -2
    var board=InlineArray[Int64,64]();for i in range(64):board[i]=-1
    board[0]=0
    if not kt_dfs(board,0,0,1):return -1
    var path=InlineArray[Int64,64]()
    for i in range(64):path[Int(board[i])]=i
    for i in range(64):let bits=UInt64(path[i]);for b in range(8):o[i*8+b]=UInt8((bits>>(8*b))&255)
    return 512
