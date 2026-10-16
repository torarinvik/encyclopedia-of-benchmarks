type Move=object
  row,col,degree:int
const Dx:array[8,int]=[1,2,2,1,-1,-2,-2,-1]
const Dy:array[8,int]=[-2,-1,1,2,2,1,-1,-2]
proc countNeighbors(board:array[64,int],row,col:int):int=
  for i in 0..<8:
    let r=row+Dy[i];let c=col+Dx[i]
    if r>=0 and r<8 and c>=0 and c<8 and board[r*8+c]==0:inc result
proc neighbors(board:array[64,int],row,col:int,moves:var array[8,Move]):int=
  for i in 0..<8:
    let r=row+Dy[i];let c=col+Dx[i]
    if r>=0 and r<8 and c>=0 and c<8 and board[r*8+c]==0:
      moves[result]=Move(row:r,col:c,degree:countNeighbors(board,r,c));inc result
  for i in 1..<result:
    let value=moves[i];var j=i
    while j>0 and moves[j-1].degree>value.degree:moves[j]=moves[j-1];dec j
    moves[j]=value
proc orphan(board:array[64,int],count,row,col:int):bool=
  if count<63:
    var moves:array[8,Move];let n=neighbors(board,row,col,moves)
    for i in 0..<n:
      if countNeighbors(board,moves[i].row,moves[i].col)==0:return true
proc solve(board:var array[64,int],row,col,count:int):bool=
  if count>64:return true
  var moves:array[8,Move];let n=neighbors(board,row,col,moves)
  if n==0 and count!=64:return false
  for i in 0..<n:
    let m=moves[i];board[m.row*8+m.col]=count
    if not orphan(board,count,m.row,m.col) and solve(board,m.row,m.col,count+1):return true
    board[m.row*8+m.col]=0
  false
proc putI64(output:ptr UncheckedArray[uint8],index:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[index*8+b]=uint8((bits shr (8*b)) and 255)
proc knights_tour_warnsdorff_open*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"knights_tour_warnsdorff_open".}=
  if length!=0:return -1
  if output.isNil or int(capacity)<512:return -2
  var board:array[64,int];board[0]=1
  if not solve(board,0,0,2):return -1
  var path:array[64,int64]
  for r in 0..<8:
    for c in 0..<8:path[board[r*8+c]-1]=int64(r*8+c)
  for i in 0..<64:putI64(output,i,path[i])
  512
