const D=8
const L=132
proc put64(output:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[pos+j]=uint8((bits shr (8*j)) and 255)
proc two_dimensional_string_matching*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"two_dimensional_string_matching".}=
  if input.isNil or length<csize_t(6) or length>csize_t(L):return -1
  let rr=input[0];let cc=input[1];let hr=input[2];let wc=input[3]
  if rr<1 or rr>D or cc<1 or cc>D or hr<1 or hr>rr or wc<1 or wc>cc:return -1
  let r=int(rr);let c=int(cc);let h=int(hr);let w=int(wc)
  if int64(length)!=4+r*c+h*w:return -1
  var text,pat:array[64,int64];var p=4
  for i in 0..<r*c:text[i]=input[p];inc p;if text[i]<0 or text[i]>3:return -1
  for i in 0..<h*w:pat[i]=input[p];inc p;if pat[i]<0 or pat[i]>3:return -1
  var prefix:array[D,int64]
  for i in 1..<h:
    var q=int(prefix[i-1])
    while q>0:
      var equal=true
      for j in 0..<w:if pat[i*w+j]!=pat[q*w+j]:equal=false
      if equal:break
      q=int(prefix[q-1])
    var equal=true
    for j in 0..<w:if pat[i*w+j]!=pat[q*w+j]:equal=false
    if equal:inc q
    prefix[i]=int64(q)
  var mark:array[D*D*D,bool]
  for tr in 0..<r:
    for col in 0..(c-w):
      for pr in 0..<h:
        var equal=true
        for j in 0..<w:if text[tr*c+col+j]!=pat[pr*w+j]:equal=false
        mark[(tr*D+col)*D+pr]=equal
  var mr,mc:array[D*D,int64];var count=0
  for col in 0..(c-w):
    var q=0
    for tr in 0..<r:
      while q>0 and not mark[(tr*D+col)*D+q]:q=int(prefix[q-1])
      if mark[(tr*D+col)*D+q]:inc q
      if q==h:mr[count]=int64(tr+1-h);mc[count]=int64(col);inc count;q=int(prefix[h-1])
  let bytes=8*(1+2*count);if output.isNil or capacity<csize_t(bytes):return -2
  put64(output,0,int64(count));for i in 0..<count:put64(output,8*(1+2*i),mr[i]);put64(output,8*(2+2*i),mc[i]);int64(bytes)
