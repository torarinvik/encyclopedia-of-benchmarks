const MaxVars=12;const MaxClauses=32;const MaxInput=98;const MaxOutput=104
proc putI64(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:output[offset+b]=uint8((bits shr (8*b)) and 255)

proc random_3sat_greedy_dpll*(values:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"random_3sat_greedy_dpll".}=
  if values==nil or length<2 or length>csize_t(MaxInput) or values[0]<3 or values[0]>MaxVars or values[1]<0 or values[1]>MaxClauses:return -1
  let nv=int(values[0]);let m=int(values[1]);if int(length)!=2+3*m:return -1
  var clauses:array[MaxClauses,array[3,int]];var lens:array[MaxClauses,int];var active:array[MaxClauses,bool]
  for i in 0..<m:
    var seen:array[MaxVars,bool]
    for j in 0..<3:
      let x=values[2+3*i+j];if x==0 or x < -nv or x>nv:return -1
      let v=int(if x>0:x else:-x)-1;if seen[v]:return -1;seen[v]=true;clauses[i][j]=int(x)
    lens[i]=3;active[i]=true
  var assigned:array[MaxVars,int];var success=false;var failed=false
  for step in 0..<nv:
    if failed:break
    var remaining=0;for i in 0..<m:if active[i]:inc remaining
    if remaining==0:success=true;break
    var chosen=0
    for i in 0..<m:
      if chosen==0 and active[i] and lens[i]==1:chosen=clauses[i][0]
    if chosen==0:
      var counts:array[2*MaxVars,int]
      for i in 0..<m:
        if active[i]:
          for j in 0..<lens[i]:let lit=clauses[i][j];let v=abs(lit)-1;inc counts[2*v+int(lit<0)]
      var best=0
      for v in 0..<nv:
        for sign in 0..<2:
          let lit=if sign==0:v+1 else:-(v+1);let c=counts[2*v+sign]
          if c>best:best=c;chosen=lit
    if chosen==0:failed=true;break
    let variable=abs(chosen)-1;assigned[variable]=if chosen>0:1 else:-1
    for i in 0..<m:
      if active[i]:
        var satisfied=false
        for j in 0..<lens[i]:if clauses[i][j]==chosen:satisfied=true
        if satisfied:active[i]=false
        else:
          var w=0
          for j in 0..<lens[i]:if clauses[i][j]!= -chosen:clauses[i][w]=clauses[i][j];inc w
          lens[i]=w;if w==0:failed=true;break
  if not failed:
    var remaining=0;for i in 0..<m:if active[i]:inc remaining
    success=remaining==0
  if success:for i in 0..<nv:if assigned[i]==0:assigned[i] = -1
  let bytes=8*(nv+1);if output==nil or int(capacity)<bytes:return -2
  var staged:array[MaxOutput,uint8];putI64(addr staged[0],0,if success:1 else:0)
  for i in 0..<nv:putI64(addr staged[0],8*(i+1),int64(assigned[i]))
  for i in 0..<bytes:output[i]=staged[i]
  int64(bytes)
