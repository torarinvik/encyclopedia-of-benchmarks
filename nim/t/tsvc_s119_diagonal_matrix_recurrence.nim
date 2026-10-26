## Clean-room TSVC s119 profile; see package rights note.
const MaxSide=8
const MaxCells=64
const MaxInputLength=130
proc put64(out:ptr UncheckedArray[uint8],pos:int,value:int64)=
 var bits=cast[uint64](value)
 for j in 0..<8:out[pos+j]=uint8(bits and 255'u64);bits=bits shr 8
proc tsvc_s119_diagonal_matrix_recurrence*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s119_diagonal_matrix_recurrence".}=
 if input.isNil or length<10 or length>MaxInputLength:return -1
 if input[0]<2 or input[0]>MaxSide or input[1]<1 or input[1]>4:return -1
 let n=int(input[0]);let passes=int(input[1]);let cells=n*n;if length!=csize_t(2+2*cells):return -1
 var a:array[MaxCells,int64];var b:array[MaxCells,int64]
 for i in 0..<cells:
  let av=input[2+i];let bv=input[2+cells+i]
  if av< -2 or av>2 or bv< -2 or bv>2:return -1
  a[i]=av;b[i]=bv
 let bytes=8*cells;if out.isNil or capacity<csize_t(bytes):return -2
 for _ in 0..<passes:
  for i in 1..<n:
   for j in 1..<n:a[i*n+j]=a[(i-1)*n+j-1]+b[i*n+j]
 for i in 0..<cells:put64(out,8*i,a[i])
 int64(cells)
