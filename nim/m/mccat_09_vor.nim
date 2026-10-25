# Copyright (C) 1996 McGill University.
# Copyright (C) 1996 McCAT System Group.
# Copyright (C) 1996 ACAPS Benchmark Administrator
#                    benadmin@acaps.cs.mcgill.ca
#
# This program is free software; you can redistribute it and/or modify
# it provided this copyright notice is maintained.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
import std/math

const MaxSites = 8
const MaxCoord = 4'i64
const CenterOffset = 1024'i64
const CenterWidth = 2049'i64
const RadiusRadix = 200_000'i64

type
  Point = object
    x, y: int64
  DPoint = object
    x, y: float64
  Priority = object
    radius2, angle: float64

proc cross(a,b,c: Point): int64 = (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)
proc length2(a,b: Point): int64 =
  let dx=b.x-a.x; let dy=b.y-a.y
  dx*dx+dy*dy

proc circleCenter(a,b,c: Point): DPoint =
  let n1x=b.x-a.x; let n1y=b.y-a.y; let n2x=c.x-b.x; let n2y=c.y-b.y
  let m1x=(float64(a.x)+float64(b.x))/2.0; let m1y=(float64(a.y)+float64(b.y))/2.0
  let m2x=(float64(b.x)+float64(c.x))/2.0; let m2y=(float64(b.y)+float64(c.y))/2.0
  let c1=float64(n1x)*m1x+float64(n1y)*m1y; let c2=float64(n2x)*m2x+float64(n2y)*m2y
  let den=float64(n1x)*float64(n2y)-float64(n1y)*float64(n2x)
  DPoint(x:(c1*float64(n2y)-float64(n1y)*c2)/den,y:(float64(n1x)*c2-c1*float64(n2x))/den)

proc pointKey(points: array[MaxSites,Point], hull: array[MaxSites*2,int], n,i:int): Priority =
  let a=points[hull[(i+n-1) mod n]]; let b=points[hull[i]]; let c=points[hull[(i+1) mod n]]
  let center=circleCenter(a,b,c); let dx=float64(b.x)-center.x; let dy=float64(b.y)-center.y
  let ax=float64(a.x-b.x); let ay=float64(a.y-b.y); let bx=float64(c.x-b.x); let by=float64(c.y-b.y)
  let dot=ax*bx+ay*by; let ratio=(dot*dot)/((ax*ax+ay*ay)*(bx*bx+by*by))
  Priority(radius2:dx*dx+dy*dy,angle:(if dot<0.0: -ratio else: ratio))

proc makeHull(points: var array[MaxSites,Point], n:int, hull: var array[MaxSites*2,int]): int =
  for i in 1..<n:
    let value=points[i]; var j=i
    while j>0 and (value.x<points[j-1].x or (value.x==points[j-1].x and value.y<points[j-1].y)):
      points[j]=points[j-1]; dec j
    points[j]=value
  var stack: array[MaxSites*2,int]; var k=0
  for i in 0..<n:
    while k>=2 and cross(points[stack[k-2]],points[stack[k-1]],points[i])<=0: dec k
    stack[k]=i; inc k
  let threshold=k+1
  for i in countdown(n-2,0):
    while k>=threshold and cross(points[stack[k-2]],points[stack[k-1]],points[i])<=0: dec k
    stack[k]=i; inc k
  dec k
  for i in 0..<k: hull[i]=stack[i]
  k

proc packCircle(points: array[MaxSites,Point], hull: array[MaxSites*2,int]): int64 =
  let tri=[points[hull[0]],points[hull[1]],points[hull[2]]]
  let sides=[length2(tri[0],tri[1]),length2(tri[1],tri[2]),length2(tri[0],tri[2])]
  var opposite=0; var u=1; var v=2; var longest=sides[0]
  if sides[1]>longest: longest=sides[1]; opposite=1; u=0; v=2
  if sides[2]>longest: longest=sides[2]; opposite=2; u=0; v=1
  let o=tri[opposite]
  let dot=float64(tri[u].x-o.x)*float64(tri[v].x-o.x)+float64(tri[u].y-o.y)*float64(tri[v].y-o.y)
  var center: DPoint; var radius: float64
  if dot<0.0:
    center=DPoint(x:(float64(tri[u].x)+float64(tri[v].x))/2.0,y:(float64(tri[u].y)+float64(tri[v].y))/2.0)
    radius=sqrt(float64(longest))/2.0
  else:
    center=circleCenter(tri[0],tri[1],tri[2]); let dx=float64(tri[0].x)-center.x; let dy=float64(tri[0].y)-center.y; radius=sqrt(dx*dx+dy*dy)
  let cx=int64(center.x); let cy=int64(center.y); let cents=int64(radius*100.0+0.5)
  if cx < -CenterOffset or cx>CenterOffset or cy < -CenterOffset or cy>CenterOffset or cents<0 or cents>=RadiusRadix: return -1
  ((cx+CenterOffset)*CenterWidth+(cy+CenterOffset))*RadiusRadix+cents

proc mccat_09_vor*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "mccat_09_vor".} =
  if input==nil or length<7 or length>17: return -1
  let count=input[0]
  if count<3 or count>MaxSites or length!=csize_t(1+2*count): return -1
  var points: array[MaxSites,Point]
  for i in 0..<int(count):
    let x=input[1+2*i]; let y=input[2+2*i]
    if x < -MaxCoord or x>MaxCoord or y < -MaxCoord or y>MaxCoord: return -1
    points[i]=Point(x:x,y:y)
    for j in 0..<i: if points[j].x==x and points[j].y==y: return -1
  for i in 0..<int(count):
    for j in i+1..<int(count):
      for k in j+1..<int(count): if cross(points[i],points[j],points[k])==0: return -1
  var hull: array[MaxSites*2,int]
  var n=makeHull(points,int(count),hull)
  if n<3 or n>MaxSites: return -1
  while n>3:
    var keys: array[MaxSites,Priority]
    for i in 0..<n: keys[i]=pointKey(points,hull,n,i)
    for i in 0..<n:
      for j in 0..<i: if keys[i].radius2==keys[j].radius2 and keys[i].angle==keys[j].angle: return -1
    var best=0
    for i in 1..<n:
      if keys[i].radius2>keys[best].radius2 or (keys[i].radius2==keys[best].radius2 and keys[i].angle<keys[best].angle): best=i
    for i in best..<n-1: hull[i]=hull[i+1]
    dec n
  packCircle(points,hull)
