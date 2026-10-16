const LIMIT:i64=1_000_000;
unsafe fn put_f64_le(output:*mut u8,offset:usize,value:f64){let bytes=value.to_le_bytes();for b in 0..8{*output.add(offset+b)=bytes[b];}}
#[no_mangle]
pub unsafe extern "C" fn solve_quadratic_equation(values:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if values.is_null()||length!=2{return -1;}let p_i=*values;let q_i=*values.add(1);if p_i < -LIMIT||p_i>LIMIT||q_i < -LIMIT||q_i>LIMIT{return -1;}
    let p=p_i as f64;let q=q_i as f64;let root=(p*p/4.0-q).sqrt();if root.is_nan(){return 0;}
    let x1=-p/2.0-root;let x2=-p/2.0+root;
    if x1==x2{if output.is_null()||capacity<8{return -2;}put_f64_le(output,0,x1);return 1;}
    if output.is_null()||capacity<16{return -2;}put_f64_le(output,0,x1);put_f64_le(output,8,x2);2
}
