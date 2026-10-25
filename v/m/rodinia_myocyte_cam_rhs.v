module rodinia_myocyte_cam_rhs

// Clean-room bounded port of Rodinia Myocyte's kernel_cam RHS.
fn cam_decode(raw i64) f32 { return f32(raw) / 1000000.0 }
fn cam_add(a f32, b f32) f32 { return a + b }
fn cam_sub(a f32, b f32) f32 { return a - b }
fn cam_mul(a f32, b f32) f32 { return a * b }
fn cam_div(a f32, b f32) f32 { return a / b }

@[export: 'rodinia_myocyte_cam_rhs']
pub fn rodinia_myocyte_cam_rhs(input &i64, length usize) f64 {
	if unsafe { input == nil } || length != 22 { return -1.0e300 }
	unsafe {
		if input[0] < 0 || input[0] > 100000000 || input[1] < 100000000 || input[1] > 200000000 || input[2] < 500000 || input[2] > 5000000 { return -1.0e300 }
		for i := 3; i < 22; i++ { if input[i] < 0 || input[i] > 10000000 { return -1.0e300 } }
		ca,k,mg := cam_decode(input[0]),cam_decode(input[1]),cam_decode(input[2])
		btot,camkii,cantot,pp1 := cam_decode(input[3]),cam_decode(input[4]),cam_decode(input[5]),cam_decode(input[6])
		mut s := []f32{len:15}
		for i := 0; i < 15; i++ { s[i]=cam_decode(input[7+i]) }
		cam,ca2cam,ca4cam,camb,ca2camb,ca4camb := s[0],s[1],s[2],s[3],s[4],s[5]
		pb2,pb,pt,pt2,pa := s[6],s[7],s[8],s[9],s[10]
		ca4can,camca4can,ca2camca4can,ca4camca4can := s[11],s[12],s[13],s[14]
		mut kd02 := f32(0); mut kd24 := f32(0)
		if mg <= f32(1) {
			kd02=f32(0.0025*(1.0+f64(k)/0.94-f64(mg)/0.012)*(1.0+f64(k)/8.1+f64(mg)/0.022))
			kd24=f32(0.128*(1.0+f64(k)/0.64+f64(mg)/0.0014)*(1.0+f64(k)/13.0-f64(mg)/0.153))
		} else {
			kd02=f32(0.0025*(1.0+f64(k)/0.94-1.0/0.012+(f64(mg)-1.0)/0.060)*(1.0+f64(k)/8.1+1.0/0.022+(f64(mg)-1.0)/0.068))
			kd24=f32(0.128*(1.0+f64(k)/0.64+1.0/0.0014+(f64(mg)-1.0)/0.005)*(1.0+f64(k)/13.0-1.0/0.153+(f64(mg)-1.0)/0.150))
		}
		if kd02 <= 0 || kd24 <= 0 { return -1.0e300 }
		k20,k42 := f32(10),f32(500); k02,k24:=cam_div(k20,kd02),cam_div(k42,kd24)
		k0boff:=f32(0.0014); k0bon:=f32(f64(k0boff)/0.2)
		k2boff,k2bon,k4boff,k4bon:=cam_div(k0boff,100),k0bon,cam_div(k0boff,100),k0bon
		k20b,k02b,k42b,k24b:=cam_div(k20,100),k02,k42,k24
		kbi:=f32(2.2); kib:=f32(f64(kbi)/33.5e-3); kpp1:=f32(1.72); kmpp1:=f32(11.5)
		kib2:=kib; kb2i:=cam_mul(kib,5); kb24:=k24; kb42:=f32(500.0*33.5e-3/5.0)
		kta:=cam_div(kbi,1000); kat:=kib; kt42:=f32(500.0*33.5e-6/5.0); kt24:=k24; kat2:=kib; kt2a:=cam_mul(kib,5)
		kcan_caoff:=f32(1); kcan_caon:=f32(1.0/0.5); kcan_cam4on:=f32(46); kcan_cam4off:=f32(0.0013)
		kcan_cam2on:=kcan_cam4on; kcan_cam2off:=cam_mul(2508,kcan_cam4off); kcan_cam0on:=kcan_cam4on; kcan_cam0off:=cam_mul(165,kcan_cam2off)
		k02can:=k02; k20can:=cam_div(k20,165); k24can:=k24; k42can:=cam_div(k20,2508)
		ca_sq:=f64(ca)*f64(ca)
		rcn02:=f32(f64(k02)*ca_sq*f64(cam)-f64(k20)*f64(ca2cam)); rcn24:=f32(f64(k24)*ca_sq*f64(ca2cam)-f64(k42)*f64(ca4cam))
		b:=cam_sub(cam_sub(cam_sub(btot,camb),ca2camb),ca4camb)
		rcn02b:=f32(f64(k02b)*ca_sq*f64(camb)-f64(k20b)*f64(ca2camb)); rcn24b:=f32(f64(k24b)*ca_sq*f64(ca2camb)-f64(k42b)*f64(ca4camb))
		rcn0b:=cam_sub(cam_mul(cam_mul(k0bon,cam),b),cam_mul(k0boff,camb)); rcn2b:=cam_sub(cam_mul(cam_mul(k2bon,ca2cam),b),cam_mul(k2boff,ca2camb)); rcn4b:=cam_sub(cam_mul(cam_mul(k4bon,ca4cam),b),cam_mul(k4boff,ca4camb))
		ca2can:=cam_sub(cam_sub(cam_sub(cam_sub(cantot,ca4can),camca4can),ca2camca4can),ca4camca4can)
		rcn_ca4can:=f32(f64(kcan_caon)*ca_sq*f64(ca2can)-f64(kcan_caoff)*f64(ca4can)); rcn02can:=f32(f64(k02can)*ca_sq*f64(camca4can)-f64(k20can)*f64(ca2camca4can)); rcn24can:=f32(f64(k24can)*ca_sq*f64(ca2camca4can)-f64(k42can)*f64(ca4camca4can))
		rcn0can:=cam_sub(cam_mul(cam_mul(kcan_cam0on,cam),ca4can),cam_mul(kcan_cam0off,camca4can)); rcn2can:=cam_sub(cam_mul(cam_mul(kcan_cam2on,ca2cam),ca4can),cam_mul(kcan_cam2off,ca2camca4can)); rcn4can:=cam_sub(cam_mul(cam_mul(kcan_cam4on,ca4cam),ca4can),cam_mul(kcan_cam4off,ca4camca4can))
		pix:=cam_sub(cam_sub(cam_sub(cam_sub(cam_sub(f32(1),pb2),pb),pt),pt2),pa)
		rcn_ckib2:=cam_sub(cam_mul(cam_mul(kib2,ca2cam),pix),cam_mul(kb2i,pb2)); rcn_ckb2b:=f32(f64(kb24)*ca_sq*f64(pb2)-f64(kb42)*f64(pb)); rcn_ckib:=cam_sub(cam_mul(cam_mul(kib,ca4cam),pix),cam_mul(kbi,pb))
		total:=cam_add(cam_add(cam_add(pb,pt),pt2),pa); kbt:=f32(0.055*f64(total)+0.0074*f64(total)*f64(total)+0.015*f64(total)*f64(total)*f64(total))
		rcn_ckbt:=cam_sub(cam_mul(kbt,pb),cam_div(cam_mul(cam_mul(kpp1,pp1),pt),cam_add(kmpp1,cam_mul(camkii,pt))))
		rcn_cktt2:=cam_sub(cam_mul(kt42,pt),f32(f64(kt24)*ca_sq*f64(pt2)))
		rcn_ckta:=cam_sub(cam_mul(kta,pt),cam_mul(cam_mul(kat,ca4cam),pa)); rcn_ckt2a:=cam_sub(cam_mul(kt2a,pt2),cam_mul(cam_mul(kat2,ca2cam),pa))
		rcn_ckt2b2:=cam_div(cam_mul(cam_mul(kpp1,pp1),pt2),cam_add(kmpp1,cam_mul(camkii,pt2))); rcn_ckai:=cam_div(cam_mul(cam_mul(kpp1,pp1),pa),cam_add(kmpp1,cam_mul(camkii,pa)))
		mut d := []f32{len:16}
		d0inner:=cam_sub(-rcn02,rcn0b); d[0]=f32(0.001*f64(cam_sub(d0inner,rcn0can)))
		term:=cam_add(cam_sub(cam_sub(cam_sub(rcn02,rcn24),rcn2b),rcn2can),cam_mul(camkii,cam_add(-rcn_ckib2,rcn_ckt2a))); d[1]=f32(0.001*f64(term))
		term=cam_add(cam_sub(cam_sub(rcn24,rcn4b),rcn4can),cam_mul(camkii,cam_add(-rcn_ckib,rcn_ckta))); d[2]=f32(0.001*f64(term))
		d[3]=f32(0.001*f64(cam_sub(rcn0b,rcn02b))); d[4]=f32(0.001*f64(cam_sub(cam_add(rcn02b,rcn2b),rcn24b))); d[5]=f32(0.001*f64(cam_add(rcn24b,rcn4b)))
		d[6]=f32(0.001*f64(cam_add(cam_sub(rcn_ckib2,rcn_ckb2b),rcn_ckt2b2))); d[7]=f32(0.001*f64(cam_sub(cam_add(rcn_ckib,rcn_ckb2b),rcn_ckbt)))
		d[8]=f32(0.001*f64(cam_sub(cam_sub(rcn_ckbt,rcn_ckta),rcn_cktt2))); d[9]=f32(0.001*f64(cam_sub(cam_sub(rcn_cktt2,rcn_ckt2a),rcn_ckt2b2))); d[10]=f32(0.001*f64(cam_sub(cam_add(rcn_ckta,rcn_ckt2a),rcn_ckai)))
		d11a:=cam_sub(rcn_ca4can,rcn0can); d11b:=cam_sub(d11a,rcn2can); d[11]=f32(0.001*f64(cam_sub(d11b,rcn4can)))
		d[12]=f32(0.001*f64(cam_sub(rcn0can,rcn02can))); d[13]=f32(0.001*f64(cam_add(cam_add(rcn2can,rcn02can),rcn24can))); d[14]=f32(0.001*f64(cam_add(rcn4can,rcn24can)))
		comsum:=cam_add(rcn02,rcn24); comsum=cam_add(comsum,rcn02b); comsum=cam_add(comsum,rcn24b); comsum=cam_add(comsum,rcn_ca4can); comsum=cam_add(comsum,rcn02can); comsum=cam_add(comsum,rcn24can)
		comterm:=cam_mul(cam_mul(f32(2),camkii),cam_sub(rcn_cktt2,rcn_ckb2b)); d[15]=f32(0.001*f64(cam_sub(comterm,cam_mul(f32(2),comsum))))
		mut checksum:=f64(0)
		for i:=0; i<16; i++ { checksum += f64(i+1)*f64(d[i]) }
		return checksum
	}
}
