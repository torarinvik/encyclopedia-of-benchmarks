const MaxN=8
const MaxOutputWords=737
proc safe(rows:array[MaxN,int],col,row:int):bool=
  for c in 0..<col:
    let prior=rows[c]
    if prior==row or prior-c==row-col or prior+c==row+col:return false
  true
proc enumerate(n,col:int,rows:var array[MaxN,int],output:var array[MaxOutputWords,int64],used:var int)=
  if col==n:
    for c in 0..<n:
      output[used]=int64(rows[c])
      inc used
    inc output[0]
    return
  for row in 0..<n:
    if safe(rows,col,row):
      rows[col]=row
      enumerate(n,col+1,rows,output,used)
proc putI64(output:ptr UncheckedArray[uint8],index:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[index*8+b]=uint8((bits shr (8*b)) and 255)
proc n_queens_backtracking_csharp*(n:int64,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"n_queens_backtracking_csharp".}=
  if n<0 or n>MaxN:return -1
  var values:array[MaxOutputWords,int64]
  var used=1
  if n>0:
    var rows:array[MaxN,int]
    enumerate(int(n),0,rows,values,used)
  let required=used*8
  if output.isNil or int(capacity)<required:return -2
  for i in 0..<used:putI64(output,i,values[i])
  int64(required)
