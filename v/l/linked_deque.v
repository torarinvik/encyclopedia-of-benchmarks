module linked_deque
@[export: 'linked_deque']
pub fn linked_deque(v &i64,n usize)i64{if n<2||n>20||n%2!=0{return -1};mut q:=[40]i64{};mut h:=usize(16);mut t:=usize(16);mut out:=i64(0);mut place:=i64(1);for p:=0;p<n;p+=2{op:=unsafe{v[p]};a:=unsafe{v[p+1]};if op<0||op>6{return -1};if op<2{if a< -15||a>15{return -1};if op==0{h--;q[h]=a}else{q[t]=a;t++};continue};if a!=0{return -1};mut d:=i64(0);if op==2{if h<t{d=q[h]+16;h++}}else if op==3{if h<t{t--;d=q[t]+16}}else if op==4{if h<t{d=q[h]+16}}else if op==5{if h<t{d=q[t-1]+16}}else{d=if h==t{1}else{2}};out+=d*place;place*=32};return out}
