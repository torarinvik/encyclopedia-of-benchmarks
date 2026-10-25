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
const MaxNoEdges=2650
const MaskX: array[36,int] = [-1,0,1,-2,-1,0,1,2,-3,-2,-1,0,1,2,3,-3,-2,-1,1,2,3,-3,-2,-1,0,1,2,3,-2,-1,0,1,2,-1,0,1]
const MaskY: array[36,int] = [-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,3,3,3]
proc brightnessTable():array[513,uint8]=
  var t:array[513,uint8]
  for d in -256..256:
    let s=float64(abs(d))/20.0;let q=s*s
    t[d+256]=uint8(100.0*exp(-(q*q*q)))
  t
proc edgeOrientation(gx,gy:int):(int,int,int)=
  var slope=if gx==0:1_000_000'f32 else:float32(gy)/float32(gx)
  let sign=if slope<0: -1 else: 1
  if slope<0:slope = -slope
  if slope<0.5:(0,1,sign) elif slope>2.0:(1,0,sign) else:(if sign>0:1 else: -1,1,sign)
proc symmetryOrientation(gx,gy,cross:int):(int,int)=
  let slope=if gy==0:1_000_000'f32 else:float32(gx)/float32(gy)
  if slope<0.5:(0,1) elif slope>2.0:(1,0) else:(if cross>0: -1 else:1,1)
proc edgeMaximum(r:array[256,int],side,y,x,a,b:int):bool=
  let v=r[y*side+x]
  v>r[(y+a)*side+x+b] and v>=r[(y-a)*side+x-b] and v>r[(y+2*a)*side+x+2*b] and v>=r[(y-2*a)*side+x-2*b]
proc active(m:array[256,uint8],at:int):int=if m[at]<8:1 else:0
proc thinEdges(response:array[256,int],middle:var array[256,uint8],side:int)=
  var y=4
  while y<side-4:
    var x=4
    while x<side-4:
      let at=y*side+x
      if active(middle,at)!=0:
        let centre=response[at]
        let n=active(middle,(y-1)*side+x-1)+active(middle,(y-1)*side+x)+active(middle,(y-1)*side+x+1)+active(middle,y*side+x-1)+active(middle,y*side+x+1)+active(middle,(y+1)*side+x-1)+active(middle,(y+1)*side+x)+active(middle,(y+1)*side+x+1)
        if n==0:middle[at]=100
        if n==1 and middle[at]<6:
          let l=[response[(y-1)*side+x-1],response[(y-1)*side+x],response[(y-1)*side+x+1],response[y*side+x-1],0,response[y*side+x+1],response[(y+1)*side+x-1],response[(y+1)*side+x],response[(y+1)*side+x+1]]
          var k=[1,1,1,1,1,1,1,1,1]
          if active(middle,(y-1)*side+x-1)!=0:k[0]=0;k[1]=0;k[3]=0;k[2]=2;k[6]=2;k[5]=3;k[7]=3;k[8]=4
          elif active(middle,(y-1)*side+x)!=0:k[1]=0;k[0]=0;k[2]=0;k[3]=2;k[5]=2;k[6]=3;k[8]=3;k[7]=4
          elif active(middle,(y-1)*side+x+1)!=0:k[2]=0;k[1]=0;k[5]=0;k[0]=2;k[8]=2;k[3]=3;k[7]=3;k[6]=4
          elif active(middle,y*side+x-1)!=0:k[3]=0;k[0]=0;k[6]=0;k[1]=2;k[7]=2;k[2]=3;k[8]=3;k[5]=4
          elif active(middle,y*side+x+1)!=0:k[5]=0;k[2]=0;k[8]=0;k[1]=2;k[7]=2;k[0]=3;k[6]=3;k[3]=4
          elif active(middle,(y+1)*side+x-1)!=0:k[6]=0;k[3]=0;k[7]=0;k[0]=2;k[8]=2;k[1]=3;k[5]=3;k[2]=4
          elif active(middle,(y+1)*side+x)!=0:k[7]=0;k[6]=0;k[8]=0;k[3]=2;k[5]=2;k[0]=3;k[2]=3;k[1]=4
          else:k[8]=0;k[5]=0;k[7]=0;k[6]=2;k[2]=2;k[1]=3;k[3]=3;k[0]=4
          var best=0;var bestY=0;var bestX=0
          for yy in 0..<3:
            for xx in 0..<3:
              let value=l[yy*3+xx]*k[yy*3+xx]
              if value>best:best=value;bestY=yy;bestX=xx
          if best>0:
            middle[(y+bestY-1)*side+x+bestX-1]=uint8(if middle[at]<4:4 else:int(middle[at])+1)
            if bestY+bestY+bestX<3:
              y+=bestY-1;x+=bestX-2
              if y<4:y=4
              if x<4:x=4
        if n==2:
          let b00=active(middle,(y-1)*side+x-1);let b02=active(middle,(y-1)*side+x+1);let b20=active(middle,(y+1)*side+x-1);let b22=active(middle,(y+1)*side+x+1)
          if b00+b02+b20+b22==2 and ((b00 or b22) and (b02 or b20))!=0:
            var mx,my:int
            if b00!=0:
              if b02!=0:mx=0;my= -1 else:mx= -1;my=0
            else:
              if b02!=0:mx=1;my=0 else:mx=0;my=1
            let ratio=float32(response[(y+my)*side+x+mx])/float32(centre)
            if float64(ratio)>0.7:
              var clear:bool
              if mx==0:clear=middle[(y+2*my)*side+x-1]>7 and middle[(y+2*my)*side+x]>7 and middle[(y+2*my)*side+x+1]>7
              else:clear=middle[y*side+x+2*mx]>7 and middle[(y-1)*side+x+2*mx]>7 and middle[(y+1)*side+x+2*mx]>7
              if clear:middle[at]=100;middle[(y+my)*side+x+mx]=3
          else:
            let b01=active(middle,(y-1)*side+x);let b12=active(middle,y*side+x+1);let b21=active(middle,(y+1)*side+x);let b10=active(middle,y*side+x-1)
            let angled=b01+b12+b21+b10==2 and ((b10 or b12) and (b01 or b21))!=0 and ((b01!=0 and (active(middle,(y-2)*side+x-1)!=0 or active(middle,(y-2)*side+x+1)!=0)) or (b10!=0 and (active(middle,(y-1)*side+x-2)!=0 or active(middle,(y+1)*side+x-2)!=0)) or (b12!=0 and (active(middle,(y-1)*side+x+2)!=0 or active(middle,(y+1)*side+x+2)!=0)) or (b21!=0 and (active(middle,(y+2)*side+x-1)!=0 or active(middle,(y+2)*side+x+1)!=0)))
            if angled:middle[at]=100;dec y; x-=2;if y<4:y=4;if x<4:x=4
        if n>2:
          let b01=active(middle,(y-1)*side+x);let b12=active(middle,y*side+x+1);let b21=active(middle,(y+1)*side+x);let b10=active(middle,y*side+x-1)
          if b01+b12+b21+b10>1:
            let b00=active(middle,(y-1)*side+x-1);let b02=active(middle,(y-1)*side+x+1);let b20=active(middle,(y+1)*side+x-1);let b22=active(middle,(y+1)*side+x+1)
            let p1=b00 or b01;let p2=b02 or b12;let p3=b22 or b21;let p4=b20 or b10
            let connected=p1+p2+p3+p4-(b01 and p2)-(b12 and p3)-(b21 and p4)-(b10 and p1)
            if connected<2:middle[at]=100;dec y;x-=2;if y<4:y=4;if x<4:x=4
      inc x
    inc y
proc susanEdges(image:var array[256,uint8],side:int,brightness:array[513,uint8])=
  var response:array[256,int]
  var middle:array[256,uint8]
  for i in 0..<side*side:middle[i]=100
  for y in 3..<side-3:
    for x in 3..<side-3:
      let center=int(image[y*side+x]);var area=100
      for k in 0..<36:area+=int(brightness[center-int(image[(y+MaskY[k])*side+x+MaskX[k]])+256])
      if area<=MaxNoEdges:response[y*side+x]=MaxNoEdges-area
  for y in 4..<side-4:
    for x in 4..<side-4:
      let at=y*side+x;let strength=response[at]
      if strength<=0:continue
      let area=MaxNoEdges-strength;var doSymmetry=area<=600
      if area>600:
        var gx=0;var gy=0
        for k in 0..<36:
          let value=int(brightness[int(image[at])-int(image[(y+MaskY[k])*side+x+MaskX[k]])+256]);gx+=MaskX[k]*value;gy+=MaskY[k]*value
        let magnitude=sqrt(float32(gx*gx+gy*gy))
        if float64(magnitude)>0.9*float64(float32(area)):
          doSymmetry=false;let(a,b,_) = edgeOrientation(gx,gy)
          if edgeMaximum(response,side,y,x,a,b):middle[at]=1
        else:doSymmetry=true
      if doSymmetry:
        var gx=0;var gy=0;var cross=0
        for k in 0..<36:
          let value=int(brightness[int(image[at])-int(image[(y+MaskY[k])*side+x+MaskX[k]])+256]);let dx=MaskX[k];let dy=MaskY[k]
          gx+=dx*dx*value;gy+=dy*abs(dy)*value;cross+=dx*dy*value
        let(a,b)=symmetryOrientation(gx,gy,cross)
        if edgeMaximum(response,side,y,x,a,b):middle[at]=2
  thinEdges(response,middle,side)
  for y in 0..<side:
    for x in 0..<side:
      if middle[y*side+x]<8:
        let at=(y-1)*side+x-1
        image[at]=255;image[at+1]=255;image[at+2]=255;image[at+side]=255;image[at+side+1]=255;image[at+side+2]=255;image[at+2*side]=255;image[at+2*side+1]=255;image[at+2*side+2]=255
  for i in 0..<side*side:if middle[i]<8:image[i]=0
proc cbench_automotive_susan_e*(input:ptr UncheckedArray[int64],inputLength:csize_t,output:ptr UncheckedArray[uint8],outputCapacity:csize_t):int64 {.cdecl,exportc:"cbench_automotive_susan_e".}=
  if input==nil or inputLength<2 or inputLength>MaxInputLength:return -1
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
  let brightness=brightnessTable();susanEdges(image,side,brightness)
  for i in 0..<count:output[i]=image[i]
  int64(count)
