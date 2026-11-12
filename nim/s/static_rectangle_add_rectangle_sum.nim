const MaxN = 32
const MaxQ = 32
const MaxCoords = 128
const Stride = 129
const Modulus = 998244353'i64

proc lower(a: array[MaxCoords, int64], n: int, x: int64): int =
  var lo = 0
  var hi = n
  while lo < hi:
    let mid = lo + (hi - lo) div 2
    if a[mid] < x: lo = mid + 1 else: hi = mid
  lo

proc put64(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[at + b] = uint8((bits shr (8 * b)) and 255'u64)

proc static_rectangle_add_rectangle_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "static_rectangle_add_rectangle_sum".} =
  if input.isNil or int(length) < 2 or int(length) > 291: return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1 or n64 > MaxN or q64 < 0 or q64 > MaxQ: return -1
  let n = int(n64)
  let q = int(q64)
  if int(length) != 2 + 5 * n + 4 * q: return -1
  var ul, ud, ur, uu, uw: array[MaxN, int64]
  var ql, qd, qr, qu: array[MaxQ, int64]
  var xs, ys: array[MaxCoords, int64]
  var nx = 0
  var ny = 0
  var off = 2
  for i in 0 ..< n:
    ul[i]=input[off]; ud[i]=input[off+1]; ur[i]=input[off+2]; uu[i]=input[off+3]; uw[i]=input[off+4]
    off += 5
    if ul[i] < 0 or ul[i] >= ur[i] or ur[i] > 1_000_000 or ud[i] < 0 or ud[i] >= uu[i] or uu[i] > 1_000_000 or uw[i] < 0 or uw[i] >= Modulus: return -1
    xs[nx]=ul[i]; xs[nx+1]=ur[i]; ys[ny]=ud[i]; ys[ny+1]=uu[i]; nx+=2; ny+=2
  for i in 0 ..< q:
    ql[i]=input[off]; qd[i]=input[off+1]; qr[i]=input[off+2]; qu[i]=input[off+3]
    off += 4
    if ql[i] < 0 or ql[i] >= qr[i] or qr[i] > 1_000_000 or qd[i] < 0 or qd[i] >= qu[i] or qu[i] > 1_000_000: return -1
    xs[nx]=ql[i]; xs[nx+1]=qr[i]; ys[ny]=qd[i]; ys[ny+1]=qu[i]; nx+=2; ny+=2
  for i in 1 ..< nx:
    let value=xs[i]; var j=i
    while j>0 and xs[j-1]>value: xs[j]=xs[j-1]; dec j
    xs[j]=value
  for i in 1 ..< ny:
    let value=ys[i]; var j=i
    while j>0 and ys[j-1]>value: ys[j]=ys[j-1]; dec j
    ys[j]=value
  var count=0
  for i in 0 ..< nx:
    if count==0 or xs[i]!=xs[count-1]: xs[count]=xs[i]; inc count
  nx=count; count=0
  for i in 0 ..< ny:
    if count==0 or ys[i]!=ys[count-1]: ys[count]=ys[i]; inc count
  ny=count
  var diff: array[MaxCoords * MaxCoords, int64]
  var prefix: array[Stride * Stride, int64]
  for k in 0 ..< n:
    let x0=lower(xs,nx,ul[k]);let x1=lower(xs,nx,ur[k]);let y0=lower(ys,ny,ud[k]);let y1=lower(ys,ny,uu[k])
    diff[x0*MaxCoords+y0]+=uw[k];diff[x1*MaxCoords+y0]-=uw[k];diff[x0*MaxCoords+y1]-=uw[k];diff[x1*MaxCoords+y1]+=uw[k]
  for i in 0 ..< nx:
    for j in 0 ..< ny:
      let at=i*MaxCoords+j;var value=diff[at]
      if i>0: value+=diff[(i-1)*MaxCoords+j]
      if j>0: value+=diff[i*MaxCoords+j-1]
      if i>0 and j>0: value-=diff[(i-1)*MaxCoords+j-1]
      diff[at]=value
  if nx>1 and ny>1:
    for i in 0 ..< nx-1:
      for j in 0 ..< ny-1:
        let value=diff[i*MaxCoords+j] mod Modulus
        let dx=(xs[i+1]-xs[i]) mod Modulus;let dy=(ys[j+1]-ys[j]) mod Modulus
        let cell=value*(dx*dy mod Modulus) mod Modulus
        let at=(i+1)*Stride+j+1
        var sum=(cell+prefix[i*Stride+j+1]+prefix[(i+1)*Stride+j]-prefix[i*Stride+j]) mod Modulus
        if sum<0: sum+=Modulus
        prefix[at]=sum
  var answers: array[MaxQ, int64]
  for k in 0 ..< q:
    let x0=lower(xs,nx,ql[k]);let x1=lower(xs,nx,qr[k]);let y0=lower(ys,ny,qd[k]);let y1=lower(ys,ny,qu[k])
    var value=prefix[x1*Stride+y1]-prefix[x0*Stride+y1]-prefix[x1*Stride+y0]+prefix[x0*Stride+y0]
    value=value mod Modulus;if value<0: value+=Modulus
    answers[k]=value
  let bytes=8*q
  if output.isNil or int(capacity)<bytes: return -2
  for k in 0 ..< q: put64(output,8*k,answers[k])
  int64(bytes)
