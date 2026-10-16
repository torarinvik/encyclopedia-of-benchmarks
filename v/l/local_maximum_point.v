module local_maximum_point
@[export: 'local_maximum_point']
pub fn local_maximum_point(v &i64,n usize)i64{if n<1||n>64{return -1};for i in 0..n{x:=unsafe{v[i]};if x< -1000000||x>1000000{return -1}};mut s:=usize(0);mut e:=n-1;for{m:=s+(e-s)/2;if (m==0||unsafe{v[m-1]}<=unsafe{v[m]})&&(m==n-1||unsafe{v[m+1]}<=unsafe{v[m]}){return i64(m)};if m>0&&unsafe{v[m-1]}>unsafe{v[m]}{e=m-1}else{s=m+1}}}
