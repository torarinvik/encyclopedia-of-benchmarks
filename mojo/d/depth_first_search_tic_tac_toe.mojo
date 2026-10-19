from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn ttt_won(board:List[Int],player:Int)->Bool:
    for i in range(3):
        if board[3*i]==player and board[3*i+1]==player and board[3*i+2]==player:return true
        if board[i]==player and board[i+3]==player and board[i+6]==player:return true
    return (board[0]==player and board[4]==player and board[8]==player) or (board[2]==player and board[4]==player and board[6]==player)
fn ttt_search(mut board:List[Int],side:Int)->Int:
    if ttt_won(board,1) or ttt_won(board,2):return -1
    var available=0
    for i in range(9):if board[i]==0:available+=1
    if available==0:return -1
    var best_rank= -1;var best_score=0;var mask=0;let other=3-side
    for i in range(9):
        if board[i]!=0:continue
        board[i]=side;var score=0
        if ttt_won(board,1):score=1
        elif ttt_won(board,2):score=2
        else:
            let child=ttt_search(board,other);score=0 if child<0 else child/512
        board[i]=0
        let rank=2 if score==side else (1 if score==0 else 0)
        if rank>best_rank:best_rank=rank;best_score=score;mask=1<<i
        elif rank==best_rank:mask|=1<<i
    return best_score*512+mask
@export("depth_first_search_tic_tac_toe")
fn depth_first_search_tic_tac_toe(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=10 or (input[0]!=1 and input[0]!=2):return -1
    var board=List[Int](capacity=9)
    for i in range(9):
        if input[i+1]<0 or input[i+1]>2:return -1
        board.append(Int(input[i+1]))
    let result=ttt_search(board,Int(input[0]))
    return 0 if result<0 else Int64(result+1)
