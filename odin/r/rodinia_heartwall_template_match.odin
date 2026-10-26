package rodinia_heartwall_template_match
import "core:c"
import "core:math"

@(export)
rodinia_heartwall_template_match :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 85 do return -1
	ir0,ic0,tr0,tc0,mask := input[0],input[1],input[2],input[3],input[4]
	if ir0<2 || ir0>8 || ic0<2 || ic0>8 || tr0<2 || tr0>4 || tc0<2 || tc0>4 || tr0>ir0 || tc0>ic0 || mask<0 do return -1
	ir,ic,tr,tc := int(ir0),int(ic0),int(tr0),int(tc0); nr,nc:=ir-tr+1,ic-tc+1; count:=nr*nc
	if (u64(mask)>>u64(count))!=0 || length!=c.size_t(5+tr*tc+ir*ic) do return -1
	for i in 5..<int(length) do if input[i]<0 || input[i]>255 do return -1
	nn:=tr*tc;ibase:=5+nn;tsum,tsq:f32=0,0
	for c0 in 0..<tc { for r0 in 0..<tr { x:=f32(input[5+c0*tr+r0]);tsum+=x;tsq+=x*x } }
	nf:=f32(nn);tm:=tsum/nf;tv:=tsq/nf-tm*tm;if !(tv>0) do return -1
	best:f32=0;besti,k:=0,0
	for c0 in 0..<nc { for r0 in 0..<nr {
		if ((u64(mask)>>u64(k))&1)!=0 { ps,pq,dot:f32=0,0,0
			for c1 in 0..<tc { for r1 in 0..<tr { x:=f32(input[5+c1*tr+r1]);y:=f32(input[ibase+(c0+c1)*ir+r0+r1]);ps+=y;pq+=y*y;dot+=x*y } }
			centered:=pq-ps*ps/nf;if centered<0 {centered=0};if !(centered>0) do return -1
			denomT:=math.sqrt(f32(nn-1))*math.sqrt(tv);score:=(dot-ps*tsum/nf)/(math.sqrt(centered)*denomT);mag:=math.abs(score)
			if math.is_nan(mag)||math.is_inf(mag) do return -1;if mag>best {best=mag;besti=k}
		};k+=1
	} }
	if output==nil || capacity<8 do return -2
	u:=u64(i64(besti));for b in 0..<8 do output[b]=u8((u>>(8*b))&255)
	return 8
}
