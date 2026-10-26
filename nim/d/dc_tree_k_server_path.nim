proc putI64(out: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: out[offset+b] = uint8((bits shr (8*b)) and 255)

proc dc_tree_k_server_path*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "dc_tree_k_server_path".} =
  if input == nil or length < 5 or length > 18: return -1
  let k0=input[0]; let q0=input[1]
  if k0<2 or k0>4 or q0<1 or q0>12: return -1
  let k=int(k0); let q=int(q0)
  if int(length)!=2+k+q: return -1
  var pos: array[4,int64]
  for i in 0..<k:
    pos[i]=input[2+i]
    if pos[i]<0 or pos[i]>15: return -1
  for r in 0..<q:
    if input[2+k+r]<0 or input[2+k+r]>15: return -1
  var staged: array[60,int64]
  var at=0
  for r in 0..<q:
    let target=input[2+k+r]
    var active: array[4,bool]
    var activeCount=0
    var nearest=high(int64)
    for i in 0..<k:
      var first=true
      for j in 0..<i:
        if pos[j]==pos[i]: first=false
      if first:
        active[i]=true; inc activeCount
        let delta=if pos[i]>target: pos[i]-target else: target-pos[i]
        if delta<nearest: nearest=delta
    staged[at]=nearest*int64(activeCount); inc at
    for i in 0..<k:
      if active[i]:
        if pos[i]<target: pos[i]+=nearest
        elif pos[i]>target: pos[i]-=nearest
    for i in 0..<k: staged[at]=pos[i]; inc at
  let bytes=8*q*(k+1)
  if output==nil or capacity<csize_t(bytes): return -2
  for i in 0..<at: putI64(output,8*i,staged[i])
  int64(bytes)
