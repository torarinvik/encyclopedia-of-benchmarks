const Prime = 2_147_483_647'i64

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[offset+b] = uint8((bits shr (8*b)) and 0xFF'u64)

proc count_min_sketch_affine*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "count_min_sketch_affine".} =
  if input.isNil or length < 3 or length > 59: return -1
  let d64=input[0]; let w64=input[1]; let ops64=input[2]
  if d64<1 or d64>4 or w64<1 or w64>8 or ops64<0 or ops64>16: return -1
  let d=int(d64); let w=int(w64); let ops=int(ops64); let start=3+2*d
  if length != csize_t(start+3*ops): return -1
  var a: array[4,int64]; var b: array[4,int64]
  for r in 0..<d:
    a[r]=input[3+2*r]; b[r]=input[4+2*r]
    if a[r]<1 or a[r]>=Prime or b[r]<0 or b[r]>=Prime: return -1
  var queries=0
  for op in 0..<ops:
    let kind=input[start+3*op]; let key=input[start+3*op+1]; let weight=input[start+3*op+2]
    if key<0 or key>1_000_000: return -1
    if kind==0:
      if weight<1 or weight>1_000_000: return -1
    elif kind==1:
      if weight!=0: return -1
      inc queries
    else: return -1
  var table: array[4,array[8,int64]]
  var staged: array[16,int64]
  var count=0
  for op in 0..<ops:
    let kind=input[start+3*op]; let key=input[start+3*op+1]; let weight=input[start+3*op+2]
    var slot: array[4,int]
    for r in 0..<d: slot[r]=int(((a[r]*key+b[r]) mod Prime) mod int64(w))
    if kind==0:
      for r in 0..<d: table[r][slot[r]] += weight
    else:
      var minimum=table[0][slot[0]]
      for r in 1..<d:
        if table[r][slot[r]]<minimum: minimum=table[r][slot[r]]
      staged[count]=minimum; inc count
  let required=queries*8
  if capacity<csize_t(required) or (required>0 and output.isNil): return -2
  for i in 0..<count: putI64Le(output,8*i,staged[i])
  int64(required)
