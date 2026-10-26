## Clean-room bounded Heartwall score/selection; see package LICENSE.txt.
import std/math
proc rodinia_heartwall_template_match*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rodinia_heartwall_template_match".} =
  if input.isNil or length < 5 or length > 85: return -1
  let ir0=input[0]; let ic0=input[1]; let tr0=input[2]; let tc0=input[3]; let mask=input[4]
  if ir0<2 or ir0>8 or ic0<2 or ic0>8 or tr0<2 or tr0>4 or tc0<2 or tc0>4 or tr0>ir0 or tc0>ic0 or mask<0: return -1
  let ir=int(ir0);let ic=int(ic0);let tr=int(tr0);let tc=int(tc0);let nr=ir-tr+1;let nc=ic-tc+1;let count=nr*nc
  if (uint64(mask) shr count)!=0 or length != csize_t(5+tr*tc+ir*ic): return -1
  for i in 5..<int(length):
    if input[i]<0 or input[i]>255:return -1
  let nn=tr*tc;let ibase=5+nn;var tsum=0'f32;var tsq=0'f32
  for c in 0..<tc:
    for r in 0..<tr:
      let x=float32(input[5+c*tr+r]);tsum=tsum+x;tsq=tsq+x*x
  let nf=float32(nn);let tm=tsum/nf;let tv=tsq/nf-tm*tm
  if not(tv>0'f32):return -1
  var best=0'f32;var besti=0;var k=0
  for c0 in 0..<nc:
    for r0 in 0..<nr:
      if ((uint64(mask) shr k) and 1'u64)!=0:
        var ps=0'f32;var pq=0'f32;var dot=0'f32
        for c in 0..<tc:
          for r in 0..<tr:
            let x=float32(input[5+c*tr+r]);let y=float32(input[ibase+(c0+c)*ir+r0+r])
            ps=ps+y;pq=pq+y*y;dot=dot+x*y
        var centered=pq-ps*ps/nf
        if centered<0'f32:centered=0'f32
        if not(centered>0'f32):return -1
        let denomT=sqrt(float32(nn-1))*sqrt(tv)
        let score=(dot-ps*tsum/nf)/(sqrt(centered)*denomT)
        let mag=abs(score)
        if classify(mag)==fcNan or classify(mag)==fcInf:return -1
        if mag>best:best=mag;besti=k
      inc k
  if output.isNil or capacity<8:return -2
  let u=cast[uint64](int64(besti))
  for b in 0..<8:output[b]=uint8((u shr (8*b)) and 255)
  8
