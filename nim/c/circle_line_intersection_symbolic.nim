## Independently authored draft; not compiled or run.
proc circle_line_intersection_symbolic*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "circle_line_intersection_symbolic".} =
  if input.isNil or length != 6: return -1
  for i in 0 ..< 6:
    if input[i] < -1000 or input[i] > 1000: return -1
  let x=input[0]; let y=input[1]; let r=input[2]
  let a=input[3]; let b=input[4]; let c=input[5]
  if r < 1 or (a == 0 and b == 0): return -1
  let d=a*a+b*b; let q=a*x+b*y+c; let h=r*r*d-q*q
  let words = [(if h < 0: 0'i64 elif h == 0: 1'i64 else: 2'i64), x*d-a*q, y*d-b*q, d, -b, a, h]
  let count = if h < 0: 1 else: 7
  let needed = 8*count
  if output.isNil or capacity < csize_t(needed): return -2
  for i in 0 ..< count:
    let bits = cast[uint64](words[i])
    for j in 0 ..< 8: output[8*i+j] = uint8((bits shr (8*j)) and 255'u64)
  int64(needed)
