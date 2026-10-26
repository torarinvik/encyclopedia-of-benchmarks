// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
#[no_mangle]
pub unsafe extern "C" fn prolangs_c_simulator_format3_4(v:*const i64,n:usize)->i64 {
    if v.is_null() || n!=7 { return -1; }
    let pc=*v; let x=*v.add(1); let b=*v.add(2);
    if pc<0 || pc>1048572 || x<0 || x>=16777216 || b<0 || b>=16777216 { return -1; }
    let mut q=[0i64;4]; for j in 0..4 { q[j]=*v.add(3+j); if q[j]<0 || q[j]>255 { return -1; } }
    let byte0=q[0] as i64; let byte1=q[1] as i64; let byte2=q[2] as i64; let byte3=q[3] as i64;
    let nf=(byte0>>1)&1; let inf=byte0&1;
    let xf=(byte1>>7)&1; let bf=(byte1>>6)&1; let pf=(byte1>>5)&1; let ef=(byte1>>4)&1;
    let sic=nf==0 && inf==0; let fmt=if ef==1 && !sic {4i64} else {3i64}; let nextpc=pc+fmt;
    let mut address:i64;
    if fmt==4 { if bf!=0 || pf!=0 {return -1;} address=((byte1&15)<<16)|(byte2<<8)|byte3; if xf!=0 {address+=x;} }
    else { address=((byte1&15)<<8)|byte2; if sic {return 0;} if bf!=0 && pf!=0 {return -1;} if xf!=0 {address+=x;} if bf!=0 {address+=b;} if pf!=0 {address=if address>=2048 {address-4096+nextpc}else{address+nextpc};} }
    if nf==1 && inf==0 {return -1;} if address<0 {return -1;} if nf==0 && inf==1 && address>=16777216 {return -1;} address
}
