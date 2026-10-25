module cbench_rsynth_natural_glottal

@[export: 'cbench_rsynth_natural_glottal_sample']
pub fn cbench_rsynth_natural_glottal_sample(input &f64,n usize,mut output &f64,cap usize)i64{
 unsafe{
  if input==nil||n==0||n>3{return -1}
  for i in 0..n{if !input[i].is_finite(){return -1}}
  if n!=2||input[0]<40.0||input[0]>263.0||input[0]!=f64(int(input[0]))||input[1]<0.0||input[1]>299.0||input[1]!=f64(int(input[1])){return -1}
  nopen:=int(input[0]);index:=int(input[1]);mut result:=f32(0)
  if index<nopen{
   b_int:=1920000/(nopen*nopen);b:=f32(b_int);product:=f32(b*f32(nopen));mut a:=f32(f64(product)*0.333);mut wave:=f32(0)
   for _ in 0..(index+1){a=f32(a-b);wave=f32(wave+a)}
   result=f32(f64(wave)*0.028)
  }
  if output==nil||cap<1{return -2};output[0]=f64(result);return 1
 }
}
