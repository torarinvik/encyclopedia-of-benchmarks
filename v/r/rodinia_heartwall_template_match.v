module rodinia_heartwall_template_match
import math

@[export: 'rodinia_heartwall_template_match']
pub fn rodinia_heartwall_template_match(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 5 || length > 85 { return -1 }
	unsafe {
		ir0,ic0,tr0,tc0,mask:=input[0],input[1],input[2],input[3],input[4]
		if ir0<2||ir0>8||ic0<2||ic0>8||tr0<2||tr0>4||tc0<2||tc0>4||tr0>ir0||tc0>ic0||mask<0{return -1}
		ir,ic,tr,tc:=int(ir0),int(ic0),int(tr0),int(tc0);nr,nc:=ir-tr+1,ic-tc+1;count:=nr*nc
		if (u64(mask)>>count)!=0||length!=usize(5+tr*tc+ir*ic){return -1}
		for i:=5;i<int(length);i++{if input[i]<0||input[i]>255{return -1}}
		nn:=tr*tc;ibase:=5+nn;mut tsum:=f32(0);mut tsq:=f32(0)
		for c:=0;c<tc;c++{for r:=0;r<tr;r++{x:=f32(input[5+c*tr+r]);tsum+=x;tsq+=x*x}}
		nf:=f32(nn);tm:=tsum/nf;tv:=tsq/nf-tm*tm;if !(tv>0){return -1}
		mut best:=f32(0);mut besti:=0;mut k:=0
		for c0:=0;c0<nc;c0++{for r0:=0;r0<nr;r0++{
			if ((u64(mask)>>k)&1)!=0{mut ps:=f32(0);mut pq:=f32(0);mut dot:=f32(0)
				for c:=0;c<tc;c++{for r:=0;r<tr;r++{x:=f32(input[5+c*tr+r]);y:=f32(input[ibase+(c0+c)*ir+r0+r]);ps+=y;pq+=y*y;dot+=x*y}}
				mut centered:=pq-ps*ps/nf;if centered<0{centered=0};if !(centered>0){return -1}
				denom_t:=f32(math.sqrt(f64(nn-1)))*f32(math.sqrt(tv));score:=(dot-ps*tsum/nf)/(f32(math.sqrt(centered))*denom_t);mag:=f32(math.abs(score))
				if math.is_inf(mag)||math.is_nan(mag){return -1};if mag>best{best=mag;besti=k}
			};k++
		}}
		if unsafe { output == nil } || capacity<8{return -2};u:=u64(i64(besti));for b:=0;b<8;b++{unsafe{output[b]=u8((u>>(8*b))&255)}};return 8
	}
}
