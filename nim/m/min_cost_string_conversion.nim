const MaxCells = 1089
proc putI64(outp: ptr UncheckedArray[uint8], pos: var int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8:
    outp[pos] = uint8((bits shr (8*b)) and 255)
    inc pos
proc min_cost_string_conversion*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "min_cost_string_conversion".} =
  if input.isNil or length < 6 or length > 70: return -1
  let n = int(length)
  let srcN = input[0]
  if srcN < 0 or srcN > 32: return -1
  let src = int(srcN); let dp = src + 1
  if dp >= n: return -1
  let dstN = input[dp]
  if dstN < 0 or dstN > 32: return -1
  let dst = int(dstN)
  if n != 6 + src + dst: return -1
  let tp = dp + 1; let cp = tp + dst
  for i in 0..<src:
    if input[1+i] < 0 or input[1+i] > 127: return -1
  for j in 0..<dst:
    if input[tp+j] < 0 or input[tp+j] > 127: return -1
  for k in 0..<4:
    if input[cp+k] < -1000 or input[cp+k] > 1000: return -1
  let cc=input[cp]; let rc=input[cp+1]; let dc=input[cp+2]; let ic=input[cp+3]
  let rows=src+1; let cols=dst+1; let cells=rows*cols
  var costs: array[MaxCells,int64]; var codes: array[MaxCells,int64]; var ca: array[MaxCells,int64]; var cb: array[MaxCells,int64]
  for j in 1..<cols:
    let x=j; costs[x]=costs[x-1]+ic; codes[x]=4; cb[x]=input[tp+j-1]
  for i in 1..<rows:
    let x=i*cols; costs[x]=costs[x-cols]+dc; codes[x]=3; ca[x]=input[i]
  for i in 1..<rows:
    for j in 1..<cols:
      let x=i*cols+j; let a=input[i]; let b=input[tp+j-1]; let same=a==b
      var best=costs[x-cols-1]+(if same: cc else: rc)
      var op=int64(if same: 1 else: 2); var aa=a; var bb=int64(if same: 0 else: b)
      let deletion=costs[x-cols]+dc
      if deletion<best: best=deletion; op=3; aa=a; bb=0
      let insertion=costs[x-1]+ic
      if insertion<best: best=insertion; op=4; aa=0; bb=b
      costs[x]=best; codes[x]=op; ca[x]=aa; cb[x]=bb
  let needed=32+cells*32
  if output.isNil or capacity < csize_t(needed): return -2
  var p=0; putI64(output,p,int64(rows)); putI64(output,p,int64(cols))
  for x in 0..<cells: putI64(output,p,costs[x])
  putI64(output,p,int64(rows)); putI64(output,p,int64(cols))
  for x in 0..<cells: putI64(output,p,codes[x]); putI64(output,p,ca[x]); putI64(output,p,cb[x])
  int64(p)
