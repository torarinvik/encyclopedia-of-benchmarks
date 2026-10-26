module prolangs_c_simulator_shiftr;

// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
fn long prolangs_c_simulator_shiftr(long* v, usz n) @export("prolangs_c_simulator_shiftr") {
	if(v==null||n!=2)return -1;
	long operand=v[0],raw=v[1];
	if(operand<0||operand>255||raw<0||raw>0xFFFFFF||(operand>>4)>=10)return -1;
	uint shift=((operand&15)+1).uint();uint value=raw.uint();uint result=value>>shift;
	if((value&0x800000)!=0)result|=((1u<<shift)-1u)<<(24u-shift);
	return (result&0xFFFFFF).long();
}
