const MaxCells=1024
proc storeLe(output:ptr UncheckedArray[uint8],offset:int,value:int64) =
  let bits=cast[uint64](value)
  for b in 0..<8: output[offset+b]=uint8((bits shr (b*8)) and 255)
proc rotate_matrix_270*(v:ptr UncheckedArray[int64],n:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"rotate_matrix_270".} =
 if v.isNil or n<2 or n>1027:return -1
 let r=v[0];let c=v[1]
 if r<1 or r>32 or c<1 or c>32 or n!=2+csize_t(r*c):return -1
 let rows=int(r);let cols=int(c);var matrix:array[MaxCells,int64];var result:array[MaxCells,int64]
 for i in 0..<rows*cols:matrix[i]=v[2+i]
 let outRows=int(cols);let outCols=int(rows)
 for i in 0..<rows:
  for j in 0..<cols:
   let rr=int(j);let cc=int(rows-1-i);result[rr*outCols+cc]=matrix[i*cols+j]
 let bytes=8*(2+outRows*outCols)
 if output.isNil or capacity<csize_t(bytes):return -2
 storeLe(output,0,int64(outRows));storeLe(output,8,int64(outCols))
 for i in 0..<outRows*outCols:storeLe(output,16+8*i,result[i])
 int64(bytes)
