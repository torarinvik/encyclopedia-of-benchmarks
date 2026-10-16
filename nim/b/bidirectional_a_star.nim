const MaxCells=400
const InfCost=1_000_000
proc heuristic(a,b,cols:int):int=
  let dy=a div cols-b div cols;let dx=a mod cols-b mod cols
  var h=0
  while (h+1)*(h+1)<=dy*dy+dx*dx:inc h
  h
proc put(outp:ptr UncheckedArray[uint8],slot:int,value:int64)=
  let bits=cast[uint64](value)
  for i in 0..<8:outp[slot*8+i]=uint8((bits shr (i*8)) and 255)
proc bidirectional_a_star*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"bidirectional_a_star".}=
  if input==nil or length<6 or input[0]<1 or input[0]>20 or input[1]<1 or input[1]>20:return -1
  let rows=int(input[0]);let cols=int(input[1]);let cells=rows*cols
  if input[2]<0 or input[2]>=rows or input[3]<0 or input[3]>=cols or input[4]<0 or input[4]>=rows or input[5]<0 or input[5]>=cols or int(length)!=6+cells:return -1
  let start=int(input[2])*cols+int(input[3]);let goal=int(input[4])*cols+int(input[5])
  var blocked:array[MaxCells,bool]
  for i in 0..<cells:if input[6+i]!=0 and input[6+i]!=1:return -1 else:blocked[i]=input[6+i]==1
  if blocked[start] or blocked[goal]:return -1
  var g,parent,order:array[2,array[MaxCells,int]];var opened,closed:array[2,array[MaxCells,bool]];var seq:array[2,int]
  for s in 0..1:for i in 0..<cells:g[s][i]=InfCost;parent[s][i]= -1
  g[0][start]=0;g[1][goal]=0;opened[0][start]=true;opened[1][goal]=true;order[0][start]=0;order[1][goal]=0;seq[0]=1;seq[1]=1
  let dr=[-1,0,1,0];let dc=[0,-1,0,1];var best=InfCost;var meet= -1
  while true:
    var minG=[InfCost,InfCost]
    for s in 0..1:for v in 0..<cells:if opened[s][v] and g[s][v]<minG[s]:minG[s]=g[s][v]
    if best<InfCost and (minG[0]==InfCost or minG[1]==InfCost or minG[0]+minG[1]>=best):break
    for s in 0..1:
      let target=if s==0:goal else:start
      var chosen= -1;var bestF=InfCost
      for v in 0..<cells:
        if opened[s][v]:
          let f=g[s][v]+heuristic(v,target,cols)
          if chosen<0 or f<bestF or (f==bestF and order[s][v]<order[s][chosen]):chosen=v;bestF=f
      if chosen<0:continue
      opened[s][chosen]=false;closed[s][chosen]=true
      if g[1-s][chosen]<InfCost and g[s][chosen]+g[1-s][chosen]<best:best=g[s][chosen]+g[1-s][chosen];meet=chosen
      let y=chosen div cols;let x=chosen mod cols
      for d in 0..<4:
        let ny=y+dr[d];let nx=x+dc[d]
        if ny<0 or ny>=rows or nx<0 or nx>=cols:continue
        let v=ny*cols+nx
        if blocked[v] or closed[s][v]:continue
        let ng=g[s][chosen]+1
        if ng<g[s][v]:
          g[s][v]=ng;parent[s][v]=chosen;opened[s][v]=true;order[s][v]=seq[s];inc seq[s]
          if g[1-s][v]<InfCost and ng+g[1-s][v]<best:best=ng+g[1-s][v];meet=v
    var any=false;for s in 0..1:for v in 0..<cells:any=any or opened[s][v]
    if not any:break
  var path,rev:array[MaxCells,int];var count=0
  if meet<0:path[0]=start;count=1
  else:
    var n=0;var v=meet
    while v>=0:rev[n]=v;inc n;v=parent[0][v]
    while n>0:dec n;path[count]=rev[n];inc count
    v=parent[1][meet];while v>=0:path[count]=v;inc count;v=parent[1][v]
  let bytes=(1+2*count)*8
  if output==nil or int(capacity)<bytes:return -2
  put(output,0,int64(count))
  for i in 0..<count:put(output,1+2*i,int64(path[i] div cols));put(output,2+2*i,int64(path[i] mod cols))
  int64(bytes)
