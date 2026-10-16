proc iso7816_d4_padding*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"iso7816_d4_padding".}=
 if n<3 or n>27:return -1
 let mode=v[0];let block=v[1];let length=v[2]
 if mode<0 or mode>2 or (mode==0 and (block<1 or block>8)) or (mode!=0 and block!=0) or length<0 or length>24 or n!=length+3:return -1
 var data:array[32,int64]
 for i in 0..<length:
  data[i]=v[i+3]
  if data[i]<0 or data[i]>255:return -1
 if mode==0:
  let output=(length div block+1)*block
  if output>32:return -1
  data[length]=128
  for i in length+1..<output:data[i]=0
  return output-length
 if mode==1:
  var i=length-1
  while i>=0 and data[i]==0:dec i
  if i>=0 and data[i]==128:return i
  return -1
 var marker:int64 = -1
 var zeroSuffix=true
 var j=length-1
 while j>=0:
  if zeroSuffix and data[j]==128:marker=j
  if data[j]!=0:zeroSuffix=false
  dec j
 if marker>=0:return length-marker
 -1
