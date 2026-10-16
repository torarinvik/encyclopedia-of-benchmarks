proc putI64Le(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0..<8: output[index*8+b]=uint8((bits shr (8*b)) and 0xFF'u64)
proc findV(order: array[32,int], n,v:int): int =
  for i in 0..<n:
    if order[i]==v:return i
  return -1
proc findN(rows: array[32,array[34,int]], deg: array[32,int],u,v:int): int =
  for i in 0..<deg[u]:
    if rows[u][i]==v:return i
  return -1
proc delN(rows: var array[32,array[34,int]],deg: var array[32,int],u,at:int) =
  for i in at..<deg[u]-1:rows[u][i]=rows[u][i+1]
  dec deg[u]
proc graph_adjacency_list*(input: ptr UncheckedArray[int64],length: csize_t,output: ptr UncheckedArray[uint8],capacity: csize_t): int64 {.cdecl,exportc:"graph_adjacency_list".} =
  if input.isNil or length<4:return -1
  let d=input[0];let nn=input[1]
  if (d!=0 and d!=1) or nn<0 or nn>32 or length<csize_t(4+nn):return -1
  var order:array[32,int];var rows:array[32,array[34,int]];var deg:array[32,int];var n=int(nn);var k=2
  for i in 0..<n:
    let x=input[k];inc k
    if x<0 or x>=32 or findV(order,i,int(x))>=0:return -1
    order[i]=int(x)
  let ec=input[k];inc k
  if ec<0 or ec>1024 or length<csize_t(k+2*ec+1):return -1
  for _ in 0..<int(ec):
    let aa=input[k];let bb=input[k+1];k+=2
    if aa<0 or aa>=32 or bb<0 or bb>=32:return -1
    let a=int(aa);let b=int(bb)
    if findV(order,n,a)<0 or findV(order,n,b)<0 or findN(rows,deg,a,b)>=0:return -1
    rows[a][deg[a]]=b;inc deg[a]
    if d==0:rows[b][deg[b]]=a;inc deg[b]
  let oo=input[k];inc k
  if oo<0 or oo>64 or length!=csize_t(k+3*oo):return -1
  let ops=int(oo);var res:array[64,int64]
  for z in 0..<ops:
    let op=input[k];let aa=input[k+1];let bb=input[k+2];k+=3
    if op==0:
      if aa<0 or aa>=32 or bb!=0 or n>=32 or findV(order,n,int(aa))>=0:return -1
      order[n]=int(aa);deg[int(aa)]=0;inc n;res[z]=1
    elif op==1:
      if aa<0 or aa>=32 or bb!=0:return -1
      let u=int(aa);let at=findV(order,n,u);if at<0:return -1
      if d==1:
        for j in 0..<n:
          let q=order[j]
          var x=findN(rows,deg,q,u)
          while x>=0:delN(rows,deg,q,x);x=findN(rows,deg,q,u)
      else:
        while deg[u]>0:
          let b=rows[u][deg[u]-1];dec deg[u]
          if b!=u:
            let x=findN(rows,deg,b,u)
            if x>=0:delN(rows,deg,b,x)
      for j in at..<n-1:order[j]=order[j+1]
      dec n;deg[u]=0;res[z]=1
    elif op==2 or op==3 or op==5:
      if aa<0 or aa>=32 or bb<0 or bb>=32:return -1
      let a=int(aa);let b=int(bb)
      if findV(order,n,a)<0 or findV(order,n,b)<0:return -1
      let x=findN(rows,deg,a,b)
      if op==5:res[z]=int64(x>=0)
      elif op==2:
        if x>=0 or deg[a]>=34 or (d==0 and deg[b]>=34):return -1
        rows[a][deg[a]]=b;inc deg[a]
        if d==0:rows[b][deg[b]]=a;inc deg[b]
        res[z]=1
      else:
        if x<0:return -1
        delN(rows,deg,a,x)
        if d==0:
          let y=findN(rows,deg,b,a);if y<0:return -1
          delN(rows,deg,b,y)
        res[z]=1
    elif op==4:
      if aa<0 or aa>=32 or bb!=0:return -1
      res[z]=int64(findV(order,n,int(aa))>=0)
    elif op==6:
      if aa!=0 or bb!=0:return -1
      n=0;deg=default(array[32,int]);res[z]=1
    else:return -1
  var words=2+ops
  for i in 0..<n:words+=2+deg[order[i]]
  if output.isNil or capacity<csize_t(words*8):return -2
  var w=0;putI64Le(output,w,oo);inc w
  for i in 0..<ops:putI64Le(output,w,res[i]);inc w
  putI64Le(output,w,int64(n));inc w
  for i in 0..<n:
    let u=order[i];putI64Le(output,w,int64(u));inc w;putI64Le(output,w,int64(deg[u]));inc w
    for j in 0..<deg[u]:putI64Le(output,w,int64(rows[u][j]));inc w
  int64(words*8)
