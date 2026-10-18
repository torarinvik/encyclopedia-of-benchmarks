const InvalidResult = -1'i64
const FactorBase = 65_536'i64
const MaxPackedLength = 21

type I64Input = ptr UncheckedArray[int64]

proc gcdI64(aInput, bInput: int64): int64 =
  var a=aInput
  var b=bInput
  if a<0: a = -a
  if b<0: b = -b
  while b!=0:
    let remainder=a mod b
    a=b
    b=remainder
  a

proc powerModI64(base, exponentInput, modulus: int64): int64 =
  var exponent=exponentInput
  var result=1'i64
  var power=base mod modulus
  while exponent>0:
    if (exponent and 1)!=0: result=(result*power) mod modulus
    power=(power*power) mod modulus
    exponent=exponent div 2
  result

proc rsa_factorization*(packed: I64Input, length: csize_t): int64 {.cdecl, exportc: "rsa_factorization".} =
  if packed==nil or length<4 or length>csize_t(MaxPackedLength): return InvalidResult
  let d=packed[0]
  let e=packed[1]
  let modulus=packed[2]
  let attempts=packed[3]
  if d<1 or d>1_000_000 or e<1 or e>1_000_000 or modulus<3 or modulus>65_535 or modulus mod 2==0 or
      attempts<1 or attempts>16 or length!=csize_t(4+attempts): return InvalidResult
  let k=d*e-1
  if k<=0 or k mod 2!=0: return InvalidResult
  for i in 0 ..< int(attempts):
    let base=packed[4+i]
    if base<2 or base>modulus-1: return InvalidResult
  for i in 0 ..< int(attempts):
    let base=packed[4+i]
    var t=k
    while t mod 2==0:
      t=t div 2
      let x=powerModI64(base,t,modulus)
      let factor=gcdI64(x-1,modulus)
      if x>1 and factor>1:
        let other=modulus div factor
        let p=min(factor,other)
        let q=max(factor,other)
        return p*FactorBase+q
  InvalidResult
