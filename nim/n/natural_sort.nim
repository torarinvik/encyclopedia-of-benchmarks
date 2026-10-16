proc lower(c:int64):int64=if c>=65 and c<=90:c+32 else:c
proc less(v:ptr UncheckedArray[int64],o:ptr UncheckedArray[int],l:ptr UncheckedArray[int],p:ptr UncheckedArray[int],a,b:int):bool=
  let lim=min(p[a],p[b])
  for i in 0..<lim:
    let x=lower(v[o[a]+i]);let y=lower(v[o[b]+i])
    if x!=y:return x<y
  if p[a]!=p[b]:return p[a]<p[b]
  let sa=l[a]-p[a];let sb=l[b]-p[b]
  if sa==0 or sb==0:return sa<sb
  var za=0;var zb=0
  while za<sa and v[o[a]+p[a]+za]==48:inc za
  while zb<sb and v[o[b]+p[b]+zb]==48:inc zb
  let na=sa-za;let nb=sb-zb
  if na!=nb:return na<nb
  for i in 0..<na:
    let x=v[o[a]+p[a]+za+i];let y=v[o[b]+p[b]+zb+i]
    if x!=y:return x<y
  false
proc natural_sort*(v:ptr UncheckedArray[int64],n:csize_t,out:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"natural_sort".}=
  if v.isNil or n<1 or n>4161 or v[0]<0 or v[0]>64:return -1
  let count=int(v[0]);var offs:array[64,int];var lens:array[64,int];var pres:array[64,int];var order:array[64,int];var cursor=1;var total=0
  for i in 0..<count:
    if cursor>=int(n) or v[cursor]<0 or v[cursor]>64:return -1
    lens[i]=int(v[cursor]);inc cursor;offs[i]=cursor;pres[i]=lens[i];var digit=false
    for j in 0..<lens[i]:
      let c=v[cursor+j]
      if c>=48 and c<=57:
        if j==0:return -1
        if not digit:pres[i]=j;digit=true
      elif not ((c>=65 and c<=90) or (c>=97 and c<=122)) or digit:return -1
    cursor+=lens[i];total+=lens[i];order[i]=i
  if cursor!=int(n):return -1
  for i in 1..<count:
    let item=order[i];var j=i
    while j>0 and less(v,addr offs[0],addr lens[0],addr pres[0],item,order[j-1]):order[j]=order[j-1];dec j
    order[j]=item
  let bytes=total+(if count>0:count-1 else:0)
  if bytes>int(cap) or (bytes>0 and out.isNil):return -2
  var w=0
  for i in 0..<count:
    if i>0:out[w]=10;inc w
    let k=order[i]
    for j in 0..<lens[k]:out[w]=uint8(v[offs[k]+j]);inc w
  int64(w)
