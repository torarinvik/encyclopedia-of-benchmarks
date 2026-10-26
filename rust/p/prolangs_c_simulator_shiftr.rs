// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
#[no_mangle]
pub unsafe extern "C" fn prolangs_c_simulator_shiftr(v:*const i64,n:usize)->i64 {
    if v.is_null()||n!=2{return -1;}let operand=*v;let raw=*v.add(1);
    if operand<0||operand>255||raw<0||raw>0xFFFFFF||(operand>>4)>=10{return -1;}
    let shift=((operand&15)+1) as u32;let value=raw as u32;let mut result=value>>shift;
    if value&0x800000!=0{result|=((1u32<<shift)-1)<<(24-shift);}
    (result&0xFFFFFF) as i64
}
