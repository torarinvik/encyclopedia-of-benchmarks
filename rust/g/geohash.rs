const ALPHABET:&[u8;32]=b"0123456789bcdefghjkmnpqrstuvwxyz";
#[no_mangle]
pub extern "C" fn geohash(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n!=2{return -1}let x=unsafe{std::slice::from_raw_parts(v,n)};if x[0]< -90000000||x[0]>90000000||x[1]< -180000000||x[1]>180000000{return -1}
 let lat=x[0] as f64/1_000_000.0;let lon=x[1] as f64/1_000_000.0;let(mut latlo,mut lathi)=(-90.0,90.0);let(mut lonlo,mut lonhi)=(-180.0,180.0);let(mut bit,mut value)=(0,0);let mut islon=true;let mut b=[0u8;12];let mut p=0;
 while p<12{let mid;if islon{mid=(lonlo+lonhi)/2.0;if lon>mid{value|=1<<(4-bit);lonlo=mid}else{lonhi=mid}}else{mid=(latlo+lathi)/2.0;if lat>mid{value|=1<<(4-bit);latlo=mid}else{lathi=mid}}islon=!islon;if bit<4{bit+=1}else{b[p]=ALPHABET[value];p+=1;bit=0;value=0}}
 if out.is_null()||cap<12{return -2}unsafe{std::ptr::copy_nonoverlapping(b.as_ptr(),out,12)}12
}
