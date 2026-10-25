/****
    Copyright (C) 1996 McGill University.
    Copyright (C) 1996 McCAT System Group.
    Copyright (C) 1996 ACAPS Benchmark Administrator
                       benadmin@acaps.cs.mcgill.ca

    This program is free software; you can redistribute it and/or modify
    it provided this copyright notice is maintained.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
****/
import math

const Header = 20
const MaxPoints = 16
const MaxInput = 68
const Micro = 1_000_000.0
const SourcePi = 3.14159265359
type Matrix = array[4, array[4, float64]]

proc identity(): Matrix =
  var m: Matrix
  for row in 0 ..< 4:
    for column in 0 ..< 4: m[row][column] = if row == column: 1.0 else: 0.0
  m
proc scaleMatrix(x,y,z: float64): Matrix =
  result = identity();result[0][0]=x;result[1][1]=y;result[2][2]=z
proc translateMatrix(x,y,z: float64): Matrix =
  result = identity();result[0][3]=x;result[1][3]=y;result[2][3]=z
proc multiply(a,b: Matrix): Matrix =
  var out: Matrix
  for row in 0 ..< 4:
    for column in 0 ..< 4:
      for k in 0 ..< 4: out[row][column] += a[row][k]*b[k][column]
  out
proc rotateMatrix(rx,ry,rz: float64): Matrix =
  let dx=SourcePi/180.0*rx;let dy=SourcePi/180.0*ry;let dz=SourcePi/180.0*rz
  let cx=cos(dx);let sx=sin(dx);let cy=cos(dy);let sy=sin(dy);let cz=cos(dz);let sz=sin(dz)
  var x=identity();var y=identity();var z=identity()
  x[1][1]=cx;x[1][2]= -sx;x[2][1]=sx;x[2][2]=cx
  y[0][0]=cy;y[0][2]=sy;y[2][0]= -sy;y[2][2]=cy
  z[0][0]=cz;z[0][1]= -sz;z[1][0]=sz;z[1][1]=cz
  multiply(multiply(x,y),z)
proc apply(m: Matrix,p: array[3,float64]): array[3,float64] =
  for row in 0 ..< 3: result[row]=p[0]*m[row][0]+p[1]*m[row][1]+p[2]*m[row][2]+m[row][3]
proc roundMilli(value: float64): int64 =
  let scaled=value*1000.0
  if scaled>=0.0: int64(floor(scaled+0.5)) else: int64(ceil(scaled-0.5))
proc bounded(value,limit:int64):bool = value>= -limit and value<=limit

proc mccat_08_main*(input: ptr UncheckedArray[int64], inputLength: csize_t): int64
    {.cdecl, exportc: "mccat_08_main".} =
  if input==nil or inputLength<Header or inputLength>MaxInput:return -1
  let framesValue=input[0];let countValue=input[1]
  if framesValue<1 or framesValue>360 or countValue<1 or countValue>MaxPoints:return -1
  let frames=int(framesValue);let count=int(countValue)
  if int(inputLength)!=Header+3*count:return -1
  for i in 2 ..< 5:if not bounded(input[i],4_000_000):return -1
  for i in 11 ..< 14:if not bounded(input[i],4_000_000):return -1
  for i in 5 ..< 8:if not bounded(input[i],360_000_000):return -1
  for i in 14 ..< 17:if not bounded(input[i],360_000_000):return -1
  for i in 8 ..< 11:if not bounded(input[i],100_000_000):return -1
  for i in 17 ..< 20:if not bounded(input[i],100_000_000):return -1
  var points:array[MaxPoints,array[3,float64]]
  var raw:array[MaxPoints,array[3,int64]]
  var unique=0
  for point in 0 ..< count:
    let coords=[input[Header+point*3],input[Header+point*3+1],input[Header+point*3+2]]
    for value in coords:if not bounded(value,100_000_000):return -1
    var duplicate=false
    for prior in 0 ..< unique:if raw[prior]==coords:duplicate=true
    if not duplicate:
      raw[unique]=coords
      for axis in 0 ..< 3:points[unique][axis]=float64(coords[axis])/Micro
      inc unique
  var checksum=0'i64
  for frame in 0 ..< frames:
    let childScale=scaleMatrix(float64(input[2])/Micro,float64(input[3])/Micro,float64(input[4])/Micro)
    let childRotation=rotateMatrix(float64(input[5])/Micro,float64(input[6])/Micro,float64(input[7])/Micro)
    let childTranslation=translateMatrix(float64(input[8])/Micro,float64(input[9])/Micro,float64(input[10])/Micro)
    let parentScale=scaleMatrix(float64(input[11])/Micro,float64(input[12])/Micro,float64(input[13])/Micro)
    let parentRotation=rotateMatrix(float64(input[14])/Micro,float64(input[15])/Micro+float64(frame),float64(input[16])/Micro)
    let parentTranslation=translateMatrix(float64(input[17])/Micro,float64(input[18])/Micro,float64(input[19])/Micro)
    for point in 0 ..< unique:
      let a=apply(childScale,points[point]);let b=apply(childRotation,a);let c=apply(childTranslation,b)
      let d=apply(parentScale,c);let e=apply(parentRotation,d);let f=apply(parentTranslation,e)
      let weight=int64(frame+1)*int64(point+1)
      checksum+=weight*(roundMilli(f[0])+3*roundMilli(f[1])+7*roundMilli(f[2]))
  checksum
