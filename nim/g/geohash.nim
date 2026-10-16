const Alphabet = "0123456789bcdefghjkmnpqrstuvwxyz"
proc geohash*(v:ptr UncheckedArray[int64],n:csize_t,output:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"geohash".} =
 if v==nil or n!=2 or v[0]< -90000000 or v[0]>90000000 or v[1]< -180000000 or v[1]>180000000:return -1
 let lat=float64(v[0])/1_000_000.0;let lon=float64(v[1])/1_000_000.0
 var latlo= -90.0;var lathi=90.0;var lonlo= -180.0;var lonhi=180.0;var bit=0;var value=0;var islon=true;var b:array[12,uint8];var p=0
 while p<12:
  var mid:float64
  if islon:
   mid=(lonlo+lonhi)/2
   if lon>mid:value=value or (1 shl (4-bit));lonlo=mid
   else:lonhi=mid
  else:
   mid=(latlo+lathi)/2
   if lat>mid:value=value or (1 shl (4-bit));latlo=mid
   else:lathi=mid
  islon=not islon
  if bit<4:inc bit
  else:b[p]=uint8(ord(Alphabet[value]));inc p;bit=0;value=0
 if output==nil or cap<12:return -2
 for i in 0..<12:output[i]=b[i]
 12
