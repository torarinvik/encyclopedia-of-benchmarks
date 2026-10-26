## Layered edit-distance shortest paths over a supplied literal NFA.
proc approximate_regex_matching*(x: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "approximate_regex_matching".} =
  if x == nil: return -2
  if length < 6 or length > 66: return -1
  let sv=x[0];let ev=x[1];let tv=x[2];let kv=x[3];let startv=x[4];let acceptv=x[5]
  if sv<2 or sv>8 or ev<1 or ev>16 or tv<0 or tv>12 or kv<0 or kv>3 or startv<0 or acceptv<0 or startv>=sv or acceptv>=sv or startv==acceptv:return -1
  let s=int(sv);let e=int(ev);let t=int(tv);let k=int(kv);let start=int(startv);let accept=int(acceptv);let ts=6+3*e
  if int(length)!=ts+t:return -1
  var from:array[16,int];var to:array[16,int];var label:array[16,uint8]
  for i in 0..<e:
    let u=x[6+3*i];let v=x[7+3*i];let c=x[8+3*i]
    if u<0 or u>=sv or v<0 or v>=sv or c<1 or c>127:return -1
    from[i]=int(u);to[i]=int(v);label[i]=uint8(c)
    for j in 0..<i:
      if from[i]==from[j] and to[i]==to[j] and label[i]==label[j]:return -1
  for i in 0..<t:
    if x[ts+i]<1 or x[ts+i]>127:return -1
  if capacity<csize_t(t) or (t>0 and output==nil):return -2
  let inf=k+1;var cur:array[8,int];var next:array[8,int]
  for q in 0..<s:cur[q]=inf
  for pos in 0..<t:
    cur[start]=0
    for pass in 0..<s-1:
      var changed=false
      for i in 0..<e:
        if cur[from[i]]<inf and cur[from[i]]+1<cur[to[i]]:cur[to[i]]=cur[from[i]]+1;changed=true
      if not changed:break
    for q in 0..<s:next[q]=if cur[q]<inf:cur[q]+1 else:inf
    for i in 0..<e:
      if cur[from[i]]<inf:
        let cost=cur[from[i]]+(if label[i]!=uint8(x[ts+pos]):1 else:0)
        if cost<next[to[i]]:next[to[i]]=cost
    for pass in 0..<s-1:
      var changed=false
      for i in 0..<e:
        if next[from[i]]<inf and next[from[i]]+1<next[to[i]]:next[to[i]]=next[from[i]]+1;changed=true
      if not changed:break
    output[csize_t(pos)]=if next[accept]<=k:1'u8 else:0'u8
    cur=next
  return int64(t)
