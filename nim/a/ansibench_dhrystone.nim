## Bounded Dhrystone 2.1 core profile; upstream public-domain notice in package LICENSE.
const I1=0; const I2=1; const I3=2; const I4=3; const I5=4
type
  Record = object
    ptrIndex, discr, enumComp, intComp: int
    text: array[31,uint8]
  State = object
    intGlob, boolGlob, ch1, ch2: int
    arr1: array[50,int]
    arr2: array[50,array[50,int]]
    rec: array[2,Record]
proc copyText(dst: var array[31,uint8], src: cstring) =
  var i=0
  while i<31:
    dst[i]=uint8(src[i])
    if src[i]=='\0': break
    inc i
proc cmpText(a,b: array[31,uint8]): int =
  for i in 0..<31:
    if a[i]!=b[i]: return (if a[i]<b[i]: -1 else: 1)
    if a[i]==0:return 0
  0
proc func1(s: var State,a,b:int):int =
  if a!=b:return I1
  s.ch1=a;I2
proc func3(e:int):bool = e==I3
proc proc7(a,b:int,outv: var int) = outv=b+(a+2)
proc proc6(s: State,v:int,outv: var int) =
  outv=v
  if not func3(v):outv=I4
  case v
  of I1:outv=I1
  of I2:outv=(if s.intGlob>100:I1 else:I4)
  of I3:outv=I2
  of I4:discard
  of I5:outv=I3
  else:discard
proc proc3(s: var State,reference:int) =
  if s.rec[0].ptrIndex>=0:s.rec[reference].ptrIndex=s.rec[0].ptrIndex
  proc7(10,s.intGlob,s.rec[0].intComp)
proc proc1(s: var State) =
  let next=s.rec[0].ptrIndex
  s.rec[next]=s.rec[0]
  s.rec[0].intComp=5;s.rec[next].intComp=s.rec[0].intComp;s.rec[next].ptrIndex=s.rec[0].ptrIndex
  proc3(s,next)
  if s.rec[next].discr==I1:
    s.rec[next].intComp=6
    var en=s.rec[next].enumComp
    proc6(s,s.rec[0].enumComp,en);s.rec[next].enumComp=en
    s.rec[next].ptrIndex=s.rec[0].ptrIndex
    proc7(s.rec[next].intComp,10,s.rec[next].intComp)
  else:s.rec[0]=s.rec[next]
proc proc2(s: State,v: var int) =
  var loc=v+10;var en=0
  while true:
    if s.ch1==ord('A'):
      dec loc;v=loc-s.intGlob;en=I1
    else:en=I2
    if en==I1:break
proc proc4(s: var State) =
  let local=(if s.ch1==ord('A'):1 else:0)
  s.boolGlob=local or s.boolGlob;s.ch2=ord('B')
proc proc5(s: var State) = s.ch1=ord('A');s.boolGlob=0
proc proc8(s: var State,a,b:int) =
  let loc=a+5;s.arr1[loc]=b;s.arr1[loc+1]=s.arr1[loc];s.arr1[loc+30]=loc
  for i in loc..loc+1:s.arr2[loc][i]=loc
  inc s.arr2[loc][loc-1];s.arr2[loc+20][loc]=s.arr1[loc];s.intGlob=5
proc func2(s: var State,a,b: array[31,uint8]):bool =
  var loc=2;var ch=0
  while loc<=2:
    if func1(s,int(a[loc]),int(b[loc+1]))==I1:ch=ord('A');inc loc
  if ch>=ord('W') and ch<ord('Z'):loc=7
  if ch==ord('R'):return true
  if cmpText(a,b)>0:loc+=7;s.intGlob=loc;return true
  false
proc ansibench_dhrystone*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"ansibench_dhrystone".} =
  if input==nil or length!=1:return -1
  if input[0]<1 or input[0]>8:return -1
  var s:State
  s.rec[0].ptrIndex=1;s.rec[0].discr=I1;s.rec[0].enumComp=I3;s.rec[0].intComp=40
  copyText(s.rec[0].text,"DHRYSTONE PROGRAM, SOME STRING")
  var str1,str2:array[31,uint8]
  copyText(str1,"DHRYSTONE PROGRAM, 1'ST STRING");s.arr2[8][7]=10
  var a,b,c,en,f2false=0
  for run in 1..int(input[0]):
    proc5(s);proc4(s);a=2;b=3;copyText(str2,"DHRYSTONE PROGRAM, 2'ND STRING");en=I2
    f2false=(if func2(s,str1,str2):0 else:1)
    while a<b:c=5*a-b;proc7(a,b,c);inc a
    proc8(s,a,c);proc1(s)
    for ch in ord('A')..s.ch2:
      if en==func1(s,ch,ord('C')):
        proc6(s,I1,en);copyText(str2,"DHRYSTONE PROGRAM, 3'RD STRING");b=run;s.intGlob=run
    b=b*a;a=b div c;b=7*(b-c)-a;proc2(s,a)
  if output==nil or capacity<19:return -2
  let values=[s.intGlob,s.boolGlob,s.ch1,s.ch2,s.arr1[8],s.arr2[8][7],s.rec[0].discr,s.rec[0].enumComp,s.rec[0].intComp,s.rec[0].ptrIndex,s.rec[1].discr,s.rec[1].enumComp,s.rec[1].intComp,s.rec[1].ptrIndex,a,b,c,en,f2false]
  for i in 0..<19:output[i]=uint8(values[i])
  19
