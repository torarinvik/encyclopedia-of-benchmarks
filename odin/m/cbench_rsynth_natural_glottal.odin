package cbench_rsynth_natural_glottal
import "core:c"

@(export, link_name="cbench_rsynth_natural_glottal_sample")
cbench_rsynth_natural_glottal_sample :: proc "c"(input:[^]f64,n:c.size_t,output:[^]f64,cap:c.size_t)->i64{
 if input==nil||n<1||n>3 do return -1
 for i:=0;i<int(n);i+=1{if input[i]!=input[i] do return -1}
 if n!=2||input[0]<40.0||input[0]>263.0||input[0]!=f64(int(input[0]))||input[1]<0.0||input[1]>299.0||input[1]!=f64(int(input[1])) do return -1
 nopen:=int(input[0]);index:=int(input[1]);result:f32=0
 if index<nopen{
  b_int:=1920000/(nopen*nopen);b:=f32(b_int);product:=f32(b*f32(nopen));a:=f32(f64(product)*0.333);wave:f32=0
  for i:=0;i<=index;i+=1{a=f32(a-b);wave=f32(wave+a)}
  result=f32(f64(wave)*0.028)
 }
 if output==nil||cap<1 do return -2
 output[0]=f64(result);return 1
}
