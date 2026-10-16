const MaxPeople=8
const MaxTasks=12
const MaxInput=2+MaxPeople*(MaxTasks+1)
proc bitmask_assignment_count*(input:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"bitmask_assignment_count".}=
  if input==nil or length<2 or length>MaxInput:return -1
  let pv=input[0];let tv=input[1]
  if pv<0 or pv>MaxPeople or tv<0 or tv>MaxTasks:return -1
  let people=int(pv);let tasks=int(tv);var freq:array[MaxTasks+1,array[MaxPeople,int64]];var pos=2
  for p in 0..<people:
    if pos>=int(length):return -1
    let c=input[pos];inc pos
    if c<0 or c>int64(MaxTasks) or pos+int(c)>int(length):return -1
    for _ in 0..<int(c):
      let task=input[pos];inc pos
      if task<1 or task>tv:return -1
      inc freq[int(task)][p]
  if pos!=int(length):return -1
  let states=1 shl people;let full=states-1;var dp:array[1 shl MaxPeople,array[MaxTasks+2,int64]]
  for mask in 0..<states:dp[mask][tasks+1]=if mask==full:1 else:0
  if tasks>0:
    for task in countdown(tasks,1):
      for mask in 0..<states:
        var ways=dp[mask][task+1]
        for p in 0..<people:
          if freq[task][p]>0 and (mask and (1 shl p))==0:ways+=freq[task][p]*dp[mask or (1 shl p)][task+1]
        dp[mask][task]=ways
  dp[0][1]
