/**********************************************************************\
  SUSAN Version 2l by Stephen Smith
  Oxford Centre for Functional Magnetic Resonance Imaging of the Brain,
  Department of Clinical Neurology, Oxford University, Oxford, UK
  (Previously in Computer Vision and Image Processing Group - now
  Computer Vision and Electro Optics Group - DERA Chertsey, UK)
  Email:    steve@fmrib.ox.ac.uk
  WWW:      http://www.fmrib.ox.ac.uk/~steve
  (C) Crown Copyright (1995-1999), Defence Evaluation and Research Agency,
  Farnborough, Hampshire, GU14 6TD, UK
  DERA WWW site:
  http://www.dera.gov.uk/
  DERA Computer Vision and Electro Optics Group WWW site:
  http://www.dera.gov.uk/imageprocessing/dera/group_home.html
  DERA Computer Vision and Electro Optics Group point of contact:
  Dr. John Savage, jtsavage@dera.gov.uk, +44 1344 633203
  A UK patent has been granted: "Method for digitally processing
  images to determine the position of edges and/or corners therein for
  guidance of unmanned vehicle", UK Patent 2272285. Proprietor:
  Secretary of State for Defence, UK. 15 January 1997

  This code is issued for research purposes only and remains the
  property of the UK Secretary of State for Defence. This code must
  not be passed on without this header information being kept
  intact. This code must not be sold.
\**********************************************************************/
import std/math
const MinSide=11
const MaxSide=16
const MaxInputLength=258
const MaxNoCorners=1850
const MaskX: array[36,int] = [-1,0,1,-2,-1,0,1,2,-3,-2,-1,0,1,2,3,-3,-2,-1,1,2,3,-3,-2,-1,0,1,2,3,-2,-1,0,1,2,-1,0,1]
const MaskY: array[36,int] = [-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3]
proc brightnessTable(): array[513,uint8] =
  var result: array[513,uint8]
  for difference in -256 .. 256:
    let scaled = float64(abs(difference)) / 20.0
    let term = scaled * scaled
    result[difference+256] = uint8(100.0 * exp(-(term*term*term)))
  result
proc ftoi(value: float32): int =
  if value < 0: int(float64(value) - 0.5) else: int(float64(value) + 0.5)
proc localCorner(response: array[256,int], side,y,x:int): bool =
  let value=response[y*side+x]
  for dy in -3 .. 3:
    for dx in -3 .. 3:
      if dx==0 and dy==0: continue
      let other=response[(y+dy)*side+x+dx]
      if dy<0 or (dy==0 and dx<0):
        if value<=other: return false
      elif value<other: return false
  true
proc susanCorners(image: var array[256,uint8],side:int,brightness:array[513,uint8]) =
  var response: array[256,int]
  var gradientX,gradientY: array[256,int]
  var pointX,pointY: array[256,int]
  var pointCount=0
  for y in 5 ..< side-5:
    for x in 5 ..< side-5:
      let center=int(image[y*side+x])
      var area=100
      for k in 0..<36: area+=int(brightness[center-int(image[(y+MaskY[k])*side+x+MaskX[k]])+256])
      if area>=MaxNoCorners: continue
      var gx=0;var gy=0
      for k in 0..<36:
        let pixel=int(image[(y+MaskY[k])*side+x+MaskX[k]])
        let weight=int(brightness[center-pixel+256])
        gx+=MaskX[k]*weight;gy+=MaskY[k]*weight
      let xx=gx*gx;let yy=gy*gy
      if xx+yy<=area*area div 2: continue
      var along=0
      if yy<xx:
        let divide=float32(gy)/float32(abs(gx));let stepX=abs(gx) div gx
        for distance in 1..3:
          let row=y+ftoi(float32(distance)*divide);let col=x+distance*stepX
          along+=int(brightness[center-int(image[row*side+col])+256])
      else:
        let divide=float32(gx)/float32(abs(gy));let stepY=abs(gy) div gy
        for distance in 1..3:
          let row=y+distance*stepY;let col=x+ftoi(float32(distance)*divide)
          along+=int(brightness[center-int(image[row*side+col])+256])
      if along>290:
        let at=y*side+x;response[at]=MaxNoCorners-area;gradientX[at]=51*gx div area;gradientY[at]=51*gy div area
  for y in 5 ..< side-5:
    for x in 5 ..< side-5:
      let at=y*side+x
      if response[at]>0 and localCorner(response,side,y,x):pointX[pointCount]=x;pointY[pointCount]=y;inc pointCount
  for point in 0..<pointCount:
    let x=pointX[point];let y=pointY[point];let at=(y-1)*side+x-1
    image[at]=255;image[at+1]=255;image[at+2]=255
    image[at+side]=255;image[at+side+1]=0;image[at+side+2]=255
    image[at+2*side]=255;image[at+2*side+1]=255;image[at+2*side+2]=255
  discard gradientX
  discard gradientY

proc cbench_automotive_susan_c*(input: ptr UncheckedArray[int64],inputLength:csize_t,output:ptr UncheckedArray[uint8],outputCapacity:csize_t):int64 {.cdecl,exportc:"cbench_automotive_susan_c".} =
  if input==nil or inputLength<2 or inputLength>MaxInputLength: return -1
  let sideValue=input[0]
  if sideValue<MinSide or sideValue>MaxSide:return -1
  let side=int(sideValue);let count=side*side
  if inputLength!=csize_t(count+1):return -1
  var image:array[256,uint8]
  for i in 0..<count:
    let pixel=input[i+1]
    if pixel<0 or pixel>255:return -1
    image[i]=uint8(pixel)
  if output==nil or outputCapacity<csize_t(count):return -2
  let brightness=brightnessTable();susanCorners(image,side,brightness)
  for i in 0..<count:output[i]=image[i]
  int64(count)
