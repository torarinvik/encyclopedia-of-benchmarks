import std/algorithm

proc p2_quantile_estimator*(v: ptr int64, n: uint64): float64 {.cdecl, exportc: "p2_quantile_estimator".} =
  if v == nil or n < 2 or n > 65 or v[0] < 1 or v[0] > 64 or n != uint64(v[0] + 1): return -1e300
  let count=int(v[0]); var q: array[5,float64]; var pos,desired: array[5,float64]; let inc: array[5,float64]=[0.0,0.25,0.5,0.75,1.0]; var seen=0
  for z in 0..<count:
    if v[z+1]<low(int32).int64 or v[z+1]>high(int32).int64:return -1e300
    let x=float64(v[z+1])
    if seen<5:
      q[seen]=x;inc seen
      if seen==5:
        q.sort
        for i in 0..4: pos[i]=float64(i+1);desired[i]=float64(i+1)
      continue
    var k=3
    if x<q[0]: q[0]=x;k=0
    else:
      for i in 1..3:
        if x<q[i]: k=i-1;break
      if x>q[4]:q[4]=x
    for i in k+1..4:pos[i]+=1.0
    for i in 0..4:desired[i]+=inc[i]
    for i in 1..3:
      let drift=desired[i]-pos[i];let sr=drift>=1.0 and pos[i+1]-pos[i]>1.0;let sl=drift<= -1.0 and pos[i-1]-pos[i]< -1.0
      if not sr and not sl:continue
      let direction=if sr:1.0 else: -1.0
      let left=pos[i]-pos[i-1];let right=pos[i+1]-pos[i]
      let candidate=q[i]+direction/(left+right)*((left+direction)*(q[i+1]-q[i])/right+(right-direction)*(q[i]-q[i-1])/left)
      if q[i-1]<candidate and candidate<q[i+1]:q[i]=candidate
      else:
        let nb=int(i)+int(direction);q[i]+=direction*(q[nb]-q[i])/(pos[nb]-pos[i])
      pos[i]+=direction
  if seen<5:
    for a in 1 ..< count:
      let x=q[a]
      var b=a
      while b>0 and q[b-1]>x:
        q[b]=q[b-1]
        dec b
      q[b]=x
    let rank=0.5*float64(count-1);let lo=int(rank);let hi=min(lo+1,count-1)
    return q[lo]+(rank-float64(lo))*(q[hi]-q[lo])
  q[2]
