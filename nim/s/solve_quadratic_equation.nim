import std/math
proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits=cast[uint64](value)
  for b in 0..<8: output[offset+b]=uint8((bits shr (8*b)) and 0xff'u64)
proc solve_quadratic_equation*(values:ptr UncheckedArray[int64], length:csize_t, output:ptr UncheckedArray[uint8], capacity:csize_t):int64 {.cdecl,exportc:"solve_quadratic_equation".}=
  if values==nil or length!=2:return -1
  let pi=values[0];let qi=values[1]
  if pi < -1_000_000 or pi>1_000_000 or qi < -1_000_000 or qi>1_000_000:return -1
  let p=float64(pi);let q=float64(qi);let root=sqrt(p*p/4.0-q)
  if root!=root:return 0
  let x1 = -p / 2.0 - root
  let x2 = -p / 2.0 + root
  if x1==x2:
    if output==nil or capacity<8:return -2
    putF64Le(output,0,x1);return 1
  if output==nil or capacity<16:return -2
  putF64Le(output,0,x1);putF64Le(output,8,x2);2
