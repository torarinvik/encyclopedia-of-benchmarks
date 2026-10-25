proc put64(out:ptr UncheckedArray[uint8],pos:int,x:int64)=
  let u=cast[uint64](x)
  for j in 0..<8:out[pos+j]=uint8((u shr (8*j)) and 255)
proc narrow(x:int64):int16=cast[int16](uint16(x and 0xffff))
proc line(d:var array[64,int16],base,k,m,n:int,r:array[12,int16])=
  var t:array[12,int64]
  for j in 0..<4:t[j]=int64(d[base+k*j])+int64(d[base+k*(7-j)]);t[7-j]=int64(d[base+k*j])-int64(d[base+k*(7-j)])
  t[8]=t[0]+t[3];t[9]=t[0]-t[3];t[10]=t[1]+t[2];t[11]=t[1]-t[2]
  d[base]=narrow((t[8]+t[10]) shr m);d[base+4*k]=narrow((t[8]-t[10]) shr m)
  t[8]=int64(narrow(t[11]+t[9]))*int64(r[10]);d[base+2*k]=narrow(t[8]+int64(narrow((t[9]*int64(r[9])) shr n)));d[base+6*k]=narrow(t[8]+int64(narrow((t[11]*int64(r[11])) shr n)))
  t[0]=int64(narrow(t[4]+t[7]))*int64(r[2]);t[1]=int64(narrow(t[5]+t[6]))*int64(r[0]);t[2]=t[4]+t[6];t[3]=t[5]+t[7];t[8]=int64(narrow(t[2]+t[3]))*int64(r[8]);t[2]=int64(narrow(t[2]))*int64(r[1])+t[8];t[3]=int64(narrow(t[3]))*int64(r[3])+t[8]
  d[base+7*k]=narrow(int64(narrow(t[4]*int64(r[4])+t[0]+t[2])) shr n);d[base+5*k]=narrow(int64(narrow(t[5]*int64(r[6])+t[1]+t[3])) shr n);d[base+3*k]=narrow(int64(narrow(t[6]*int64(r[5])+t[1]+t[2])) shr n);d[base+k]=narrow(int64(narrow(t[7]*int64(r[7])+t[0]+t[3])) shr n)
proc edn_jpeg_dct*(values:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"edn_jpeg_dct".}=
  if values.isNil or length!=76:return -1
  var d:array[64,int16];var r:array[12,int16]
  for i in 0..<64:if values[i]< -8 or values[i]>8:return -1 else:d[i]=int16(values[i])
  for i in 0..<12:if values[64+i]< -32 or values[64+i]>31:return -1 else:r[i]=int16(values[64+i])
  if output.isNil or capacity<512:return -2
  for row in 0..<8:line(d,row*8,1,0,13,r)
  for col in 0..<8:line(d,col,8,3,16,r)
  for i in 0..<64:put64(output,8*i,int64(d[i]))
  512
