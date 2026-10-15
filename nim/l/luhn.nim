proc luhn_validate*(input:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"luhn_validate".} =
  if input==nil or length<1:return -1
  let n=input[0]
  if n<2 or n>64 or n mod 2!=0 or length!=csize_t(n+1):return -1
  var sum=0'i64
  for i in 0..<int(n):
    var digit=input[i+1]
    if digit<0 or digit>9:return -1
    if i mod 2==0:digit*=2;if digit>9:digit-=9
    sum+=digit
  if sum mod 10==0:1 else:0
