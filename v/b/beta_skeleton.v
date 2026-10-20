// Bounded beta=2 lune graph adapted from ParGeo; see benchmarks/b/beta_skeleton/LICENSE.txt.
module beta_skeleton

@[export: 'beta_skeleton']
pub fn beta_skeleton(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 65 { return -1 }
		n0 := input[0]
		if n0 < 1 || n0 > 32 || input_length != usize(1+2*n0) { return -1 }
		n := int(n0)
		mut x := [32]i64{}
		mut y := [32]i64{}
		for i in 0 .. n { x[i]=input[1+2*i]; y[i]=input[2+2*i]; if x[i]<-1000 || x[i]>1000 || y[i]<-1000 || y[i]>1000 { return -1 }; for j in 0 .. i { if x[i]==x[j] && y[i]==y[j] { return -1 } } }
		mut edges := [992]u8{}
		mut count := 0
		for i in 0 .. n { for j in i+1 .. n { dx:=x[i]-x[j];dy:=y[i]-y[j];d2:=dx*dx+dy*dy;mut blocked:=false
			for k in 0 .. n { if k==i || k==j { continue }; aix:=x[k]-x[i];aiy:=y[k]-y[i];ajx:=x[k]-x[j];ajy:=y[k]-y[j];if aix*aix+aiy*aiy<d2 && ajx*ajx+ajy*ajy<d2 { blocked=true;break } }
			if !blocked { edges[count]=u8(i);edges[count+1]=u8(j);count+=2 }
		} }
		if output == nil || output_capacity < usize(count) { return -2 }
		for i in 0 .. count { output[i]=edges[i] }
		return i64(count)
	}
}
