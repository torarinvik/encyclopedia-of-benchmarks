# Clean-room TSVC s116 profile; see package rights note.
proc tsvc_s116_unrolled_product_chain*(input:ptr UncheckedArray[int64],length:csize_t,out:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"tsvc_s116_unrolled_product_chain".}=
 if input.isNil or length<8 or length>23:return -1
 let nr=input[0];let pr=input[1]
 if nr<6 or nr>21 or (nr-1) mod 5!=0 or pr<1 or pr>4:return -1
 let n=int(nr);if length!=csize_t(2+n):return -1
 var a:array[21,int64]
 for k in 0..<n:let x=input[2+k];if x != -1 and x != 1:return -1;a[k]=x
 if out.isNil or capacity<csize_t(8*n):return -2
 for p in 0..<int(pr):var i=0;while i<n-5:a[i]=a[i+1]*a[i];a[i+1]=a[i+2]*a[i+1];a[i+2]=a[i+3]*a[i+2];a[i+3]=a[i+4]*a[i+3];a[i+4]=a[i+5]*a[i+4];i+=5
 for k in 0..<n:var bits=cast[uint64](a[k]);for j in 0..<8:out[8*k+j]=uint8(bits and 255'u64);bits=bits shr 8
 int64(n)
