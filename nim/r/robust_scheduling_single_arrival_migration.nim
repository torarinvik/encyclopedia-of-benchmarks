const MaxMachines=3
const MaxOldJobs=8
const MaxInput=20
const MaxOutput=88

proc exactOpt(machines:int,sizes:array[MaxOldJobs+1,int64],jobs:int):int64=
  var codes=1
  for _ in 0..<jobs:codes*=machines
  var best:int64=0
  for i in 0..<jobs:best+=sizes[i]
  for code in 0..<codes:
    var loads:array[MaxMachines,int64]
    var remaining=code
    for j in 0..<jobs:
      let target=remaining mod machines;remaining=remaining div machines
      loads[target]+=sizes[j]
    var makespan=loads[0]
    for machine in 1..<machines:
      if loads[machine]>makespan:makespan=loads[machine]
    if makespan<best:best=makespan
  best

proc put64(outp:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:outp[pos+j]=uint8((bits shr (8*j)) and 255)

proc robust_scheduling_single_arrival_migration*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"robust_scheduling_single_arrival_migration".}=
  if input.isNil or length<csize_t(6) or length>csize_t(MaxInput):return -1
  let m64=input[0];let n64=input[1];let claim=input[2];let newSize=input[3]
  if m64<2 or m64>MaxMachines or n64<1 or n64>MaxOldJobs or claim<1 or newSize<1 or newSize>20 or int64(length)!=4+2*n64:return -1
  let m=int(m64);let n=int(n64)
  var sizes:array[MaxOldJobs+1,int64]
  var assignment:array[MaxOldJobs+1,int]
  var loads:array[MaxMachines,int64]
  for i in 0..<n:
    let size=input[4+2*i];let machine=input[5+2*i]
    if size<1 or size>20 or machine<0 or machine>=m64:return -1
    sizes[i]=size;assignment[i]=int(machine);loads[int(machine)]+=size
  sizes[n]=newSize
  let optimum=exactOpt(m,sizes,n+1)
  if optimum!=claim:return -1
  var moved=0'i64
  if 2*newSize<=optimum:
    var target=0
    for machine in 1..<m:
      if loads[machine]<loads[target]:target=machine
    assignment[n]=target;loads[target]+=newSize
  else:
    var source= -1
    for machine in 0..<m:
      var eligible=true;var volume=0'i64
      for i in 0..<n:
        if assignment[i]==machine:
          if 2*sizes[i]>optimum:eligible=false
          volume+=sizes[i]
      if eligible and volume>=newSize:source=machine;break
    if source<0:return -1
    var removed:array[MaxOldJobs,bool];var volume=0'i64
    for i in 0..<n:
      if assignment[i]==source:
        removed[i]=true;volume+=sizes[i];loads[source]-=sizes[i]
        if volume>=newSize:break
    if volume<newSize:return -1
    assignment[n]=source;loads[source]+=newSize
    for i in 0..<n:
      if removed[i]:
        var target=0
        for machine in 1..<m:
          if loads[machine]<loads[target]:target=machine
        assignment[i]=target;loads[target]+=sizes[i]
        if target!=source:moved+=sizes[i]
  let bytes=8*(n+3)
  if output.isNil or capacity<csize_t(bytes):return -2
  var staged:array[MaxOutput,uint8]
  put64(cast[ptr UncheckedArray[uint8]](addr staged[0]),0,optimum)
  put64(cast[ptr UncheckedArray[uint8]](addr staged[0]),8,moved)
  for i in 0..n:put64(cast[ptr UncheckedArray[uint8]](addr staged[0]),8*(i+2),int64(assignment[i]))
  for i in 0..<bytes:output[i]=staged[i]
  int64(bytes)
