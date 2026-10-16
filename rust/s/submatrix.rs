use std::slice;
fn feed(mut h:u64,x:i64)->u64{let u=x as u64;for b in 0..8{h^=(u>>(8*b))&255;h=h.wrapping_mul(0x100000001b3)}h}
#[no_mangle]
pub extern "C" fn submatrix(v:*const i64,n:usize)->i64{
 if v.is_null()||n<6||n>70{return -1}let a=unsafe{slice::from_raw_parts(v,n)};let(rows,cols,rs,cs,nr,nc)=(a[0],a[1],a[2],a[3],a[4],a[5]);if rows<1||rows>8||cols<1||cols>8||rows*cols>64||n!=6+(rows*cols)as usize{return -1}if rs<0||rs>rows||cs<0||cs>cols||nr<0||nr>rows||nc<0||nc>cols||rs+nr>rows||cs+nc>cols{return -1}if a[6..].iter().any(|x|*x<i32::MIN as i64||*x>i32::MAX as i64){return -1}
 let mut h=feed(0xcbf29ce484222325,nr);h=feed(h,nc);for r in 0..nr{for c in 0..nc{h=feed(h,a[6+((rs+r)*cols+cs+c)as usize])}}h as i64
}
