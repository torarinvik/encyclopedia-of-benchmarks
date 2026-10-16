proc neural_network_perceptron_classifier*(v:ptr UncheckedArray[int64],n:csize_t,o:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"neural_network_perceptron_classifier".}=
 if v==nil or n<5:return -1
 let f=v[0];let s=v[1];let bias=v[2]
 if f<1 or f>3 or s<1 or s>4 or bias < -10000 or bias>10000 or n!=3+int(f)+int(f*s):return -1
 for i in 0..<int(f):if v[3+i] < -10000 or v[3+i]>10000:return -1
 for i in 3+int(f)..<int(n):if v[i] < -10 or v[i]>10:return -1
 if o==nil or cap<int(s):return -2
 for j in 0..<int(s):
  var z=bias
  for i in 0..<int(f):z+=v[3+i]*v[3+int(f)+i*int(s)+j]
  o[j]=uint8(z>0)
 int64(s)
