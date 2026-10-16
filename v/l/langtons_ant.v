module langtons_ant
@[export: 'langtons_ant']
pub fn langtons_ant(v &i64,n usize)i64{if n!=1{return -1};steps:=unsafe{v[0]};if steps<0||steps>6{return -1};mut b:=[25]bool{};for i in 0..25{b[i]=true};mut x:=i64(2);mut y:=i64(2);mut d:=i64(3);dx:=[4]i64{-1,0,1,0};dy:=[4]i64{0,1,0,-1};for _ in 0..steps{old:=x*5+y;if b[old]{d=(d+1)%4}else{d=(d+3)%4};x+=dx[d];y+=dy[d];b[old]=!b[old]};mut mask:=i64(0);for i in 0..25{if !b[i]{mask|=i64(1)<<i}};return mask|((x*5+y)<<25)|(d<<30)}
