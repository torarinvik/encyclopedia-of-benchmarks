const MaxOps=8
const MaxInput=1+13*MaxOps
type IFPF=object
  typ:uint8
  sign:uint8
  exp:int16
  mant:uint64
proc stickyRight(v:var IFPF,n:int)=
  for _ in 0..<n:
    let lost=v.mant and 1'u64
    v.mant=v.mant shr 1
    if lost!=0:v.mant=v.mant or 1'u64
proc roundResult(v:var IFPF)=
  if v.typ==2:v.mant=v.mant and not 7'u64
proc normalize(v:var IFPF)=
  while (v.mant shr 63)==0:v.mant=v.mant shl 1;dec v.exp
proc addSub(x0,y0:IFPF,op:uint8):IFPF=
  var x=x0;var y=y0
  var z=IFPF(typ:2,sign:x.sign,exp:x.exp,mant:0)
  let d=int(x.exp)-int(y.exp)
  if d>0:stickyRight(y,d)
  elif d<0:stickyRight(x,-d);z.sign=y.sign xor op;z.exp=y.exp
  if (x.sign xor y.sign xor op)!=0:
    z.mant=x.mant-y.mant
    if x.mant<y.mant:z.sign=y.sign xor op;z.mant=y.mant-x.mant
    if z.mant==0:z.typ=0;z.sign=0;z.exp= -32767
    else:normalize(z)
  else:
    z.mant=x.mant+y.mant
    if z.mant<x.mant:inc z.exp;z.mant=(z.mant shr 1) or 0x8000000000000000'u64
  roundResult(z);z
proc multiply(x,y:IFPF):IFPF=
  var z=IFPF(typ:2,sign:x.sign xor y.sign,exp:x.exp+y.exp,mant:0)
  var high=0'u64;var low=0'u64;var mult=y.mant
  for _ in 0..<64:
    var carry=0'u64
    if (mult and 1)!=0:
      let old=high;high=high+x.mant
      if high<old:carry=1
    mult=mult shr 1
    let outgoing=high and 1
    high=(high shr 1) or (carry shl 63)
    low=(low shr 1) or (outgoing shl 63)
  while (high shr 63)==0:
    let carry=low shr 63;low=low shl 1;high=(high shl 1) or carry;dec z.exp
  if low==0:high=high or 1
  z.mant=high;roundResult(z);z
proc divideEmulated(x,y:IFPF):IFPF=
  var z=IFPF(typ:2,sign:x.sign xor y.sign,exp:x.exp-y.exp+128,mant:0)
  var dividend=x.mant;var rem=0'u64
  while (z.mant shr 63)==0:
    let carry=dividend shr 63;dividend=dividend shl 1
    let overflow=rem shr 63;rem=(rem shl 1) or carry
    var bit=0'u64
    if overflow!=0 or rem>=y.mant:rem=rem-y.mant;bit=1
    z.mant=(z.mant shl 1) or bit;dec z.exp
  roundResult(z);z
proc nbench_emulated_float_arithmetic*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"nbench_emulated_float_arithmetic".}=
  if input==nil or length<14 or length>MaxInput+1:return -1
  let raw=input[0]
  if raw<1 or raw>MaxOps or length!=1+csize_t(13*raw):return -1
  let n=int(raw)
  var results:array[MaxOps,IFPF]
  for i in 0..<n:
    let p=1+13*i
    let op=input[p];let sx=input[p+1];let ex=input[p+2];let sy=input[p+7];let ey=input[p+8]
    if op<0 or op>3 or sx<0 or sx>1 or sy<0 or sy>1 or ex< -8 or ex>8 or ey< -8 or ey>8:return -1
    var mx=0'u64;var my=0'u64
    for j in 0..<4:
      let a=input[p+3+j];let b=input[p+9+j]
      if a<0 or a>65535 or b<0 or b>65535:return -1
      mx=(mx shl 16) or uint64(a);my=(my shl 16) or uint64(b)
    if (mx shr 63)==0 or (my shr 63)==0:return -1
    let x=IFPF(typ:2,sign:uint8(sx),exp:int16(ex),mant:mx)
    let y=IFPF(typ:2,sign:uint8(sy),exp:int16(ey),mant:my)
    case op
    of 0:results[i]=addSub(x,y,0)
    of 1:results[i]=addSub(x,y,1)
    of 2:results[i]=multiply(x,y)
    else:results[i]=divideEmulated(x,y)
    if results[i].typ==2 and (results[i].exp< -32 or results[i].exp>32 or (results[i].mant shr 63)==0):return -1
  let bytes=n*12
  if output==nil or capacity<csize_t(bytes):return -2
  for i in 0..<n:
    let v=results[i];let p=12*i
    output[p]=v.typ;output[p+1]=v.sign
    let e=cast[uint16](v.exp);output[p+2]=uint8(e);output[p+3]=uint8(e shr 8)
    for j in 0..<4:
      let w=uint16(v.mant shr (48-16*j));output[p+4+2*j]=uint8(w);output[p+5+2*j]=uint8(w shr 8)
  int64(bytes)
