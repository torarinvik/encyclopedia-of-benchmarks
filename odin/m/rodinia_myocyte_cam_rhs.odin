package rodinia_myocyte_cam_rhs

import "core:c"

// Clean-room bounded port of Rodinia Myocyte's kernel_cam RHS.
cam_decode :: proc(v: i64) -> f32 { return f32(v) / 1_000_000.0 }

@(export)
rodinia_myocyte_cam_rhs :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length != 22 do return -1.0e300
	if input[0] < 0 || input[0] > 100_000_000 || input[1] < 100_000_000 || input[1] > 200_000_000 || input[2] < 500_000 || input[2] > 5_000_000 do return -1.0e300
	for i in 3 ..< 22 do if input[i] < 0 || input[i] > 10_000_000 do return -1.0e300
	ca, k, mg := cam_decode(input[0]), cam_decode(input[1]), cam_decode(input[2])
	btot, camkii, cantot, pp1 := cam_decode(input[3]), cam_decode(input[4]), cam_decode(input[5]), cam_decode(input[6])
	s: [15]f32
	for i in 0 ..< 15 do s[i] = cam_decode(input[7+i])
	cam, ca2cam, ca4cam, camb, ca2camb, ca4camb := s[0],s[1],s[2],s[3],s[4],s[5]
	pb2,pb,pt,pt2,pa := s[6],s[7],s[8],s[9],s[10]
	ca4can,camca4can,ca2camca4can,ca4camca4can := s[11],s[12],s[13],s[14]
	var kd02,kd24: f32
	if mg <= 1 {
		kd02=f32(0.0025*(1.0+f64(k)/0.94-f64(mg)/0.012)*(1.0+f64(k)/8.1+f64(mg)/0.022))
		kd24=f32(0.128*(1.0+f64(k)/0.64+f64(mg)/0.0014)*(1.0+f64(k)/13.0-f64(mg)/0.153))
	} else {
		kd02=f32(0.0025*(1.0+f64(k)/0.94-1.0/0.012+(f64(mg)-1.0)/0.060)*(1.0+f64(k)/8.1+1.0/0.022+(f64(mg)-1.0)/0.068))
		kd24=f32(0.128*(1.0+f64(k)/0.64+1.0/0.0014+(f64(mg)-1.0)/0.005)*(1.0+f64(k)/13.0-1.0/0.153+(f64(mg)-1.0)/0.150))
	}
	if kd02 <= 0 || kd24 <= 0 do return -1.0e300
	k20,k42: f32=10,500
	k02,k24 := k20/kd02,k42/kd24
	k0boff: f32=0.0014; k0bon:=f32(f64(k0boff)/0.2)
	k2boff,k2bon,k4boff,k4bon := k0boff/100,k0bon,k0boff/100,k0bon
	k20b,k02b,k42b,k24b := k20/100,k02,k42,k24
	kbi: f32=2.2; kib:=f32(f64(kbi)/33.5e-3); kpp1: f32=1.72; kmpp1: f32=11.5
	kib2:=kib; kb2i:=kib*5; kb24:=k24; kb42:=f32(500.0*33.5e-3/5.0)
	kta:=kbi/1000; kat:=kib; kt42:=f32(500.0*33.5e-6/5.0); kt24:=k24; kat2:=kib; kt2a:=kib*5
	kcan_caoff: f32=1; kcan_caon:=f32(1.0/0.5); kcan_cam4on: f32=46; kcan_cam4off: f32=0.0013
	kcan_cam2on:=kcan_cam4on; kcan_cam2off:=f32(2508)*kcan_cam4off; kcan_cam0on:=kcan_cam4on; kcan_cam0off:=f32(165)*kcan_cam2off
	k02can:=k02; k20can:=k20/165; k24can:=k24; k42can:=k20/2508
	ca_sq:=f64(ca)*f64(ca)
	rcn02:=f32(f64(k02)*ca_sq*f64(cam)-f64(k20)*f64(ca2cam)); rcn24:=f32(f64(k24)*ca_sq*f64(ca2cam)-f64(k42)*f64(ca4cam))
	b:=((btot-camb)-ca2camb)-ca4camb
	rcn02b:=f32(f64(k02b)*ca_sq*f64(camb)-f64(k20b)*f64(ca2camb)); rcn24b:=f32(f64(k24b)*ca_sq*f64(ca2camb)-f64(k42b)*f64(ca4camb))
	rcn0b:=k0bon*cam*b-k0boff*camb; rcn2b:=k2bon*ca2cam*b-k2boff*ca2camb; rcn4b:=k4bon*ca4cam*b-k4boff*ca4camb
	ca2can:=((((cantot-ca4can)-camca4can)-ca2camca4can)-ca4camca4can)
	rcn_ca4can:=f32(f64(kcan_caon)*ca_sq*f64(ca2can)-f64(kcan_caoff)*f64(ca4can))
	rcn02can:=f32(f64(k02can)*ca_sq*f64(camca4can)-f64(k20can)*f64(ca2camca4can))
	rcn24can:=f32(f64(k24can)*ca_sq*f64(ca2camca4can)-f64(k42can)*f64(ca4camca4can))
	rcn0can:=kcan_cam0on*cam*ca4can-kcan_cam0off*camca4can; rcn2can:=kcan_cam2on*ca2cam*ca4can-kcan_cam2off*ca2camca4can; rcn4can:=kcan_cam4on*ca4cam*ca4can-kcan_cam4off*ca4camca4can
	pix:=((((1.0-pb2)-pb)-pt)-pt2)-pa
	rcn_ckib2:=kib2*ca2cam*pix-kb2i*pb2; rcn_ckb2b:=f32(f64(kb24)*ca_sq*f64(pb2)-f64(kb42)*f64(pb)); rcn_ckib:=kib*ca4cam*pix-kbi*pb
	total:=((pb+pt)+pt2)+pa; kbt:=f32(0.055*f64(total)+0.0074*f64(total)*f64(total)+0.015*f64(total)*f64(total)*f64(total))
	rcn_ckbt:=kbt*pb-(kpp1*pp1*pt)/(kmpp1+camkii*pt); rcn_cktt2:=kt42*pt-f32(f64(kt24)*ca_sq*f64(pt2))
	rcn_ckta:=kta*pt-kat*ca4cam*pa; rcn_ckt2a:=kt2a*pt2-kat2*ca2cam*pa
	rcn_ckt2b2:=(kpp1*pp1*pt2)/(kmpp1+camkii*pt2); rcn_ckai:=(kpp1*pp1*pa)/(kmpp1+camkii*pa)
	d: [16]f32
	d[0]=f32(1e-3*f64((-rcn02-rcn0b)-rcn0can))
	term:=(((rcn02-rcn24)-rcn2b)-rcn2can)+camkii*(-rcn_ckib2+rcn_ckt2a); d[1]=f32(1e-3*f64(term))
	term=((rcn24-rcn4b)-rcn4can)+camkii*(-rcn_ckib+rcn_ckta); d[2]=f32(1e-3*f64(term))
	d[3]=f32(1e-3*f64(rcn0b-rcn02b)); d[4]=f32(1e-3*f64((rcn02b+rcn2b)-rcn24b)); d[5]=f32(1e-3*f64(rcn24b+rcn4b))
	d[6]=f32(1e-3*f64((rcn_ckib2-rcn_ckb2b)+rcn_ckt2b2)); d[7]=f32(1e-3*f64((rcn_ckib+rcn_ckb2b)-rcn_ckbt))
	d[8]=f32(1e-3*f64((rcn_ckbt-rcn_ckta)-rcn_cktt2)); d[9]=f32(1e-3*f64((rcn_cktt2-rcn_ckt2a)-rcn_ckt2b2)); d[10]=f32(1e-3*f64((rcn_ckta+rcn_ckt2a)-rcn_ckai))
	d[11]=f32(1e-3*f64(((rcn_ca4can-rcn0can)-rcn2can)-rcn4can)); d[12]=f32(1e-3*f64(rcn0can-rcn02can)); d[13]=f32(1e-3*f64((rcn2can+rcn02can)+rcn24can)); d[14]=f32(1e-3*f64(rcn4can+rcn24can))
	comsum:=((((((rcn02+rcn24)+rcn02b)+rcn24b)+rcn_ca4can)+rcn02can)+rcn24can)
	d[15]=f32(1e-3*f64((2*camkii*(rcn_cktt2-rcn_ckb2b))-(2*comsum)))
	checksum: f64=0
	for i in 0 ..< 16 do checksum += f64(i+1)*f64(d[i])
	return checksum
}
