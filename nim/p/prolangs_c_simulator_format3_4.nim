## (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
proc prolangs_c_simulator_format3_4*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc.} =
  if v == nil or n != 7: return -1
  let pc=v[0]; let x=v[1]; let b=v[2]
  if pc < 0 or pc > 1048572 or x < 0 or x >= 16777216 or b < 0 or b >= 16777216: return -1
  for j in 3 .. 6:
    if v[j] < 0 or v[j] > 255: return -1
  let byte0=int(v[3]); let byte1=int(v[4]); let byte2=int(v[5]); let byte3=int(v[6])
  let nf=(byte0 shr 1) and 1; let inf=byte0 and 1
  let xf=(byte1 shr 7) and 1; let bf=(byte1 shr 6) and 1; let pf=(byte1 shr 5) and 1; let ef=(byte1 shr 4) and 1
  let sic = nf == 0 and inf == 0
  let fmt = if ef == 1 and not sic: 4'i64 else: 3'i64
  let nextpc=pc+fmt
  var address: int64
  if fmt == 4:
    if bf != 0 or pf != 0: return -1
    address=(int64(byte1 and 15) shl 16) or (int64(byte2) shl 8) or int64(byte3)
    if xf != 0: address += x
  else:
    address=(int64(byte1 and 15) shl 8) or int64(byte2)
    if sic: return 0 # Source falls through to its final return(0) for n=i=0.
    if bf != 0 and pf != 0: return -1
    if xf != 0: address += x
    if bf != 0: address += b
    if pf != 0:
      if address >= 2048: address=address-4096+nextpc
      else: address += nextpc
  if nf == 1 and inf == 0: return -1
  if address < 0: return -1
  if nf == 0 and inf == 1 and address >= 16777216: return -1
  address
