module prolangs_c_simulator_format3_4

// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
@[export: 'prolangs_c_simulator_format3_4']
pub fn prolangs_c_simulator_format3_4(v &i64, n usize) i64 {
	unsafe {
		if v == nil || n != 7 { return -1 }
		pc,x,b := v[0],v[1],v[2]
		if pc<0 || pc>1048572 || x<0 || x>=16777216 || b<0 || b>=16777216 { return -1 }
		for j:=3;j<7;j++ { if v[j]<0 || v[j]>255 { return -1 } }
		byte0,byte1,byte2,byte3:=int(v[3]),int(v[4]),int(v[5]),int(v[6])
		nf,inf:=(byte0>>1)&1,byte0&1
		xf,bf,pf,ef:=(byte1>>7)&1,(byte1>>6)&1,(byte1>>5)&1,(byte1>>4)&1
		sic:=nf==0 && inf==0
		mut fmt:=i64(3);if ef==1 && !sic {fmt=4}
		nextpc:=pc+fmt
		mut address:=i64(0)
		if fmt==4 {
			if bf!=0 || pf!=0 {return -1}
			address=i64((byte1&15)<<16 | byte2<<8 | byte3);if xf!=0 {address+=x}
		} else {
			address=i64((byte1&15)<<8 | byte2);if sic {return 0}
			if bf!=0 && pf!=0 {return -1}
			if xf!=0 {address+=x};if bf!=0 {address+=b}
			if pf!=0 {if address>=2048 {address=address-4096+nextpc}else{address+=nextpc}}
		}
		if nf==1 && inf==0 {return -1};if address<0{return -1};if nf==0 && inf==1 && address>=16777216 {return -1};return address
	}
}
