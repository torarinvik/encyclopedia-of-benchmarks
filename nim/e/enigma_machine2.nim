const Rotor = ["EGZWVONAHDCLFQMSIPJBYUKXTR", "FOBHMDKEXQNRAULPGSJVTYICZW", "ZJXESIUQLHAVRMDOYGTNFWPBKC"]
proc enigma_machine2*(a: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "enigma_machine2".} =
  if a.isNil or length < 4 or length > 16: return -1
  let n=a[0]
  if n<0 or n>12 or length != csize_t(4+n): return -1
  var p: array[3,int]
  for j in 0..2:
    if a[j+1]<1 or a[j+1]>26: return -1
    p[j]=int(a[j+1])-1
  for i in 0..<int(n):
    if a[4+i]<0 or a[4+i]>25: return -1
  var resultValue=0'i64
  for i in 0..<int(n):
    var x=int(a[4+i])
    for r in 0..2: x=(ord(Rotor[r][(x+p[r]) mod 26])-ord('A'))
    x=(x+13) mod 26
    for r in countdown(2,0):
      let z=Rotor[r].find(char(ord('A')+x))
      x=((z-p[r]) mod 26+26) mod 26
    resultValue=resultValue*26+int64(x)
    inc p[0]
    if p[0]==26:
      p[0]=0;inc p[1]
      if p[1]==26:p[1]=0;p[2]=(p[2]+1) mod 26
  resultValue
