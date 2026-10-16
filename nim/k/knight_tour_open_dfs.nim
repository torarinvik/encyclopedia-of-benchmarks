const Dr:array[8,int]=[2,1,-1,-2,-2,-1,1,2]
const Dc:array[8,int]=[1,2,2,1,-1,-2,-2,-1]
proc solve(board:var array[64,int],row,col,step:int):bool=
  if step==64:return true
  for mv in 0..<8:
    let r=row+Dr[mv];let c=col+Dc[mv];let index=r*8+c
    if r>=0 and r<8 and c>=0 and c<8 and board[index]== -1:
      board[index]=step
      if solve(board,r,c,step+1):return true
      board[index]= -1
  false
proc putI64(output:ptr UncheckedArray[uint8],index:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[index*8+b]=uint8((bits shr (8*b)) and 255)
proc knight_tour_open_dfs*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"knight_tour_open_dfs".}=
  if length!=0:return -1
  if output.isNil or int(capacity)<512:return -2
  var board:array[64,int]
  for i in 0..<64:board[i]= -1
  board[0]=0
  if not solve(board,0,0,1):return -1
  var path:array[64,int64]
  for row in 0..<8:
    for col in 0..<8:path[board[row*8+col]]=int64(row*8+col)
  for i in 0..<64:putI64(output,i,path[i])
  512
