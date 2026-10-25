## Clean-room bounded port of Rodinia Myocyte's kernel_cam RHS; see package LICENSE.txt.
const InputLength = 22

proc decode(raw: int64): float32 = float32(raw) / 1_000_000.0'f32
proc addf(a, b: float32): float32 = a + b
proc subf(a, b: float32): float32 = a - b
proc mulf(a, b: float32): float32 = a * b
proc divf(a, b: float32): float32 = a / b

proc rodinia_myocyte_cam_rhs*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "rodinia_myocyte_cam_rhs".} =
  const Invalid = -1.0e300
  if input.isNil or length != csize_t(InputLength): return Invalid
  if input[0] < 0 or input[0] > 100_000_000 or input[1] < 100_000_000 or input[1] > 200_000_000 or input[2] < 500_000 or input[2] > 5_000_000: return Invalid
  for i in 3 ..< InputLength:
    if input[i] < 0 or input[i] > 10_000_000: return Invalid
  let Ca=decode(input[0]); let K=decode(input[1]); let Mg=decode(input[2])
  let Btot=decode(input[3]); let CaMKIItot=decode(input[4]); let CaNtot=decode(input[5]); let PP1tot=decode(input[6])
  var s: array[15, float32]
  for i in 0 ..< 15: s[i] = decode(input[7+i])
  let CaM=s[0]; let Ca2CaM=s[1]; let Ca4CaM=s[2]; let CaMB=s[3]; let Ca2CaMB=s[4]; let Ca4CaMB=s[5]
  let Pb2=s[6]; let Pb=s[7]; let Pt=s[8]; let Pt2=s[9]; let Pa=s[10]
  let Ca4CaN=s[11]; let CaMCa4CaN=s[12]; let Ca2CaMCa4CaN=s[13]; let Ca4CaMCa4CaN=s[14]

  var Kd02, Kd24: float32
  if Mg <= 1.0'f32:
    Kd02 = float32(0.0025 * (1.0 + float64(K)/0.94 - float64(Mg)/0.012) * (1.0 + float64(K)/8.1 + float64(Mg)/0.022))
    Kd24 = float32(0.128 * (1.0 + float64(K)/0.64 + float64(Mg)/0.0014) * (1.0 + float64(K)/13.0 - float64(Mg)/0.153))
  else:
    Kd02 = float32(0.0025 * (1.0 + float64(K)/0.94 - 1.0/0.012 + (float64(Mg)-1.0)/0.060) * (1.0 + float64(K)/8.1 + 1.0/0.022 + (float64(Mg)-1.0)/0.068))
    Kd24 = float32(0.128 * (1.0 + float64(K)/0.64 + 1.0/0.0014 + (float64(Mg)-1.0)/0.005) * (1.0 + float64(K)/13.0 - 1.0/0.153 + (float64(Mg)-1.0)/0.150))
  if Kd02 <= 0.0'f32 or Kd24 <= 0.0'f32: return Invalid

  let k20=10.0'f32; let k02=divf(k20,Kd02); let k42=500.0'f32; let k24=divf(k42,Kd24)
  let k0Boff=0.0014'f32; let k0Bon=float32(float64(k0Boff)/0.2); let k2Boff=divf(k0Boff,100.0'f32); let k2Bon=k0Bon; let k4Boff=k2Boff; let k4Bon=k0Bon
  let k20B=divf(k20,100.0'f32); let k02B=k02; let k42B=k42; let k24B=k24
  let kbi=2.2'f32; let kib=float32(float64(kbi)/33.5e-3); let kpp1=1.72'f32; let Kmpp1=11.5'f32
  let kib2=kib; let kb2i=mulf(kib2,5.0'f32); let kb24=k24; let kb42=float32(float64(k42)*33.5e-3/5.0); let kta=divf(kbi,1000.0'f32); let kat=kib
  let kt42=float32(float64(k42)*33.5e-6/5.0); let kt24=k24; let kat2=kib; let kt2a=mulf(kib,5.0'f32)
  let kcanCaoff=1.0'f32; let kcanCaon=float32(float64(kcanCaoff)/0.5); let kcanCaM4on=46.0'f32; let kcanCaM4off=0.0013'f32; let kcanCaM2on=kcanCaM4on
  let kcanCaM2off=mulf(2508.0'f32,kcanCaM4off); let kcanCaM0on=kcanCaM4on; let kcanCaM0off=mulf(165.0'f32,kcanCaM2off)
  let k02can=k02; let k20can=divf(k20,165.0'f32); let k24can=k24; let k42can=divf(k20,2508.0'f32)
  let ca2=float64(Ca)*float64(Ca)
  let rcn02=float32(float64(k02)*ca2*float64(CaM)-float64(k20)*float64(Ca2CaM))
  let rcn24=float32(float64(k24)*ca2*float64(Ca2CaM)-float64(k42)*float64(Ca4CaM))
  let B=subf(subf(subf(Btot,CaMB),Ca2CaMB),Ca4CaMB)
  let rcn02B=float32(float64(k02B)*ca2*float64(CaMB)-float64(k20B)*float64(Ca2CaMB))
  let rcn24B=float32(float64(k24B)*ca2*float64(Ca2CaMB)-float64(k42B)*float64(Ca4CaMB))
  let rcn0B=subf(mulf(mulf(k0Bon,CaM),B),mulf(k0Boff,CaMB)); let rcn2B=subf(mulf(mulf(k2Bon,Ca2CaM),B),mulf(k2Boff,Ca2CaMB)); let rcn4B=subf(mulf(mulf(k4Bon,Ca4CaM),B),mulf(k4Boff,Ca4CaMB))
  let Ca2CaN=subf(subf(subf(subf(CaNtot,Ca4CaN),CaMCa4CaN),Ca2CaMCa4CaN),Ca4CaMCa4CaN)
  let rcnCa4CaN=float32(float64(kcanCaon)*ca2*float64(Ca2CaN)-float64(kcanCaoff)*float64(Ca4CaN))
  let rcn02CaN=float32(float64(k02can)*ca2*float64(CaMCa4CaN)-float64(k20can)*float64(Ca2CaMCa4CaN))
  let rcn24CaN=float32(float64(k24can)*ca2*float64(Ca2CaMCa4CaN)-float64(k42can)*float64(Ca4CaMCa4CaN))
  let rcn0CaN=subf(mulf(mulf(kcanCaM0on,CaM),Ca4CaN),mulf(kcanCaM0off,CaMCa4CaN)); let rcn2CaN=subf(mulf(mulf(kcanCaM2on,Ca2CaM),Ca4CaN),mulf(kcanCaM2off,Ca2CaMCa4CaN)); let rcn4CaN=subf(mulf(mulf(kcanCaM4on,Ca4CaM),Ca4CaN),mulf(kcanCaM4off,Ca4CaMCa4CaN))
  let Pix=subf(subf(subf(subf(subf(1.0'f32,Pb2),Pb),Pt),Pt2),Pa)
  let rcnCKib2=subf(mulf(mulf(kib2,Ca2CaM),Pix),mulf(kb2i,Pb2))
  let rcnCKb2b=float32(float64(kb24)*ca2*float64(Pb2)-float64(kb42)*float64(Pb))
  let rcnCKib=subf(mulf(mulf(kib,Ca4CaM),Pix),mulf(kbi,Pb))
  let T=addf(addf(addf(Pb,Pt),Pt2),Pa); let Td=float64(T)
  let kbt=float32(0.055*Td+0.0074*Td*Td+0.015*Td*Td*Td)
  let rcnCKbt=subf(mulf(kbt,Pb),divf(mulf(mulf(kpp1,PP1tot),Pt),addf(Kmpp1,mulf(CaMKIItot,Pt))))
  let rcnCKtt2=subf(mulf(kt42,Pt),float32(float64(kt24)*ca2*float64(Pt2)))
  let rcnCKta=subf(mulf(kta,Pt),mulf(mulf(kat,Ca4CaM),Pa)); let rcnCKt2a=subf(mulf(kt2a,Pt2),mulf(mulf(kat2,Ca2CaM),Pa))
  let rcnCKt2b2=divf(mulf(mulf(kpp1,PP1tot),Pt2),addf(Kmpp1,mulf(CaMKIItot,Pt2))); let rcnCKai=divf(mulf(mulf(kpp1,PP1tot),Pa),addf(Kmpp1,mulf(CaMKIItot,Pa)))
  var d: array[16, float32]
  let d0_inner=subf(-rcn02,rcn0B)
  d[0]=float32(0.001*float64(subf(d0_inner,rcn0CaN)))
  var term=addf(subf(subf(subf(rcn02,rcn24),rcn2B),rcn2CaN),mulf(CaMKIItot,addf(-rcnCKib2,rcnCKt2a)))
  d[1]=float32(0.001*float64(term)); term=addf(subf(subf(rcn24,rcn4B),rcn4CaN),mulf(CaMKIItot,addf(-rcnCKib,rcnCKta)))
  d[2]=float32(0.001*float64(term))
  d[3]=float32(0.001*float64(subf(rcn0B,rcn02B))); d[4]=float32(0.001*float64(subf(addf(rcn02B,rcn2B),rcn24B))); d[5]=float32(0.001*float64(addf(rcn24B,rcn4B)))
  d[6]=float32(0.001*float64(addf(subf(rcnCKib2,rcnCKb2b),rcnCKt2b2))); d[7]=float32(0.001*float64(subf(addf(rcnCKib,rcnCKb2b),rcnCKbt)))
  d[8]=float32(0.001*float64(subf(subf(rcnCKbt,rcnCKta),rcnCKtt2))); d[9]=float32(0.001*float64(subf(subf(rcnCKtt2,rcnCKt2a),rcnCKt2b2)))
  d[10]=float32(0.001*float64(subf(addf(rcnCKta,rcnCKt2a),rcnCKai)))
  let d11a=subf(rcnCa4CaN,rcn0CaN); let d11b=subf(d11a,rcn2CaN)
  d[11]=float32(0.001*float64(subf(d11b,rcn4CaN)))
  d[12]=float32(0.001*float64(subf(rcn0CaN,rcn02CaN))); d[13]=float32(0.001*float64(subf(addf(rcn2CaN,rcn02CaN),rcn24CaN))); d[14]=float32(0.001*float64(addf(rcn4CaN,rcn24CaN)))
  var comsum=addf(rcn02,rcn24); comsum=addf(comsum,rcn02B); comsum=addf(comsum,rcn24B); comsum=addf(comsum,rcnCa4CaN); comsum=addf(comsum,rcn02CaN); comsum=addf(comsum,rcn24CaN)
  let comterm=mulf(mulf(2.0'f32,CaMKIItot),subf(rcnCKtt2,rcnCKb2b))
  d[15]=float32(0.001*float64(subf(comterm,mulf(2.0'f32,comsum))))
  var checksum=0.0
  for i in 0 ..< 16: checksum += float64(i+1)*float64(d[i])
  checksum

export fn rodinia_myocyte_cam_rhs(input: i64&, length: usize) -> f64 = rodinia_myocyte_cam_rhs_impl
