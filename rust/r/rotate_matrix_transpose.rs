const MAX_CELLS:usize=1024;
fn store_le(out:&mut [u8],off:usize,value:i64){out[off..off+8].copy_from_slice(&value.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn rotate_matrix_transpose(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<2||n>1027{return -1;}let a=std::slice::from_raw_parts(v,n);let r=a[0];let c=a[1];if !(1..=32).contains(&r)||!(1..=32).contains(&c)||n!=2+r as usize*c as usize{return -1;}
 let rows=r as usize;let cols=c as usize;let mut matrix=[0i64;MAX_CELLS];let mut result=[0i64;MAX_CELLS];matrix[..rows*cols].copy_from_slice(&a[2..]);let(orows,ocols)=(cols,rows);
 for i in 0..rows{for j in 0..cols{let(rr,cc)=(j,i);result[rr*ocols+cc]=matrix[i*cols+j];}}
 let bytes=8*(2+orows*ocols);if out.is_null()||cap<bytes{return -2;}let dst=std::slice::from_raw_parts_mut(out,bytes);store_le(dst,0,orows as i64);store_le(dst,8,ocols as i64);for i in 0..orows*ocols{store_le(dst,16+8*i,result[i]);}bytes as i64
}
