module prolangs_c_simulator_shiftr

// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
@[export: 'prolangs_c_simulator_shiftr']
pub fn prolangs_c_simulator_shiftr(v &i64, n usize) i64 {
	unsafe {
		if v == nil || n != 2 { return -1 }
		operand,raw:=v[0],v[1]
		if operand<0 || operand>255 || raw<0 || raw>0xffffff || (operand>>4)>=10 { return -1 }
		shift:=u32((operand&15)+1);value:=u32(raw);mut result:=value>>shift
		if value&0x800000!=0 { result|=((u32(1)<<shift)-1)<<(24-shift) }
		return i64(result&0xffffff)
	}
}
