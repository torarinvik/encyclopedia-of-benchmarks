import std/math

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 0xFF'u64)

proc triangle*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "triangle".} =
  if input.isNil or length != 6: return -1
  for i in 0 ..< 6:
    if input[i] < -100 or input[i] > 100: return -1
  let x1=float64(input[0]);let y1=float64(input[1]);let x2=float64(input[2]);let y2=float64(input[3]);let x3=float64(input[4]);let y3=float64(input[5])
  if x1==x2 or x1==x3 or x2==x3 or y3==y1 or y3==y2: return -1
  let determinant=x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2)
  if determinant==0.0: return -1
  let s1=x1*x1+y1*y1;let s2=x2*x2+y2*y2;let s3=x3*x3+y3*y3
  let circumX=(s1*(y2-y3)+s2*(y3-y1)+s3*(y1-y2))/(2.0*determinant)
  let circumY=-(s1*(x2-x3)+s2*(x3-x1)+s3*(x1-x2))/(2.0*determinant)
  let sideA=hypot(x2-x3,y2-y3);let sideB=hypot(x1-x3,y1-y3);let sideC=hypot(x1-x2,y1-y2);let perimeter=sideA+sideB+sideC
  let incenterX=(sideA*x1+sideB*x2+sideC*x3)/perimeter;let incenterY=(sideA*y1+sideB*y2+sideC*y3)/perimeter
  let invM1=-(x3-x1)/(y3-y1);let invM2=-(x3-x2)/(y3-y2);let rhs1=invM2*x1-y1;let rhs2=invM1*x2-y2;let solveDet=invM1-invM2
  if solveDet==0.0: return -1
  let orthoX=(-rhs1+rhs2)/solveDet;let orthoY=(invM2*rhs2-invM1*rhs1)/solveDet
  if capacity<48 or output.isNil: return -2
  let values=[circumX,circumY,incenterX,incenterY,orthoX,orthoY]
  for i in 0 ..< 6: putF64Le(output,i*8,values[i])
  48
