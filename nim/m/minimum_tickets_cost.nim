proc minimum_tickets_cost*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"minimum_tickets_cost".}=
 if v.isNil or n<4 or n>369 or v[0]<0 or v[0]>365:return -1
 let d=int(v[0]);if n!=csize_t(d+4):return -1
 var travel:array[366,bool]
 for i in 0..<d:
  let x=v[i+1];if x<1 or x>365 or travel[int(x)]:return -1
  travel[int(x)]=true
 var c:array[3,int64]
 for i in 0..2:
  c[i]=v[d+1+i];if c[i]<0 or c[i]>1_000_000:return -1
 var dp:array[397,int64]
 for day in countdown(365,1):
  dp[day]=dp[day+1]
  if travel[day]:dp[day]=min(c[0]+dp[day+1],min(c[1]+dp[day+7],c[2]+dp[day+30]))
 dp[1]
