module equal_loudness_filter

fn first_a(i int) i64 { match i {
 0 { return 1073741824 }
 1 { return -3875279605 }
 2 { return 7242592440 }
 3 { return -9849938776 }
 4 { return 11019995787 }
 5 { return -10310050823 }
 6 { return 8022431451 }
 7 { return -5130046574 }
 8 { return 2558322377 }
 9 { return -874363774 }
 10 { return 153873500 }
 else { return 0 }
 } }
fn first_b(i int) i64 { match i {
 0 { return 60930872 }
 1 { return -44894685 }
 2 { return -5549718 }
 3 { return -9621322 }
 4 { return -7681698 }
 5 { return 30506759 }
 6 { return -32060412 }
 7 { return 22380311 }
 8 { return -4826655 }
 9 { return 8028337 }
 10 { return -4488672 }
 else { return 0 }
 } }
fn second_a(i int) i64 { match i {
 0 { return 1089966811 }
 1 { return -2146993250 }
 2 { return 1057516837 }
 3 { return 0 }
 4 { return 0 }
 5 { return 0 }
 6 { return 0 }
 7 { return 0 }
 8 { return 0 }
 9 { return 0 }
 10 { return 0 }
 else { return 0 }
 } }
fn second_b(i int) i64 { match i {
 0 { return 1073619225 }
 1 { return -2147238449 }
 2 { return 1073619225 }
 3 { return 0 }
 4 { return 0 }
 5 { return 0 }
 6 { return 0 }
 7 { return 0 }
 8 { return 0 }
 9 { return 0 }
 10 { return 0 }
 else { return 0 }
 } }
fn step(sample i64,high bool,order int,mut x []i64,mut y []i64) i64 {
 mut acc:=if high {second_b(0)*sample} else {first_b(0)*sample}
 for i in 1..order+1 { bi:=if high {second_b(i)} else {first_b(i)};ai:=if high {second_a(i)} else {first_a(i)};acc+=bi*x[i-1]-ai*y[i-1] }
 a0:=if high {second_a(0)} else {first_a(0)}
 out:=acc/a0
 for i:=1;i<order;i++ {x[order-i]=x[order-i-1];y[order-i]=y[order-i-1]}
 if order>0 {x[0]=sample;y[0]=out}
 return out
}
@[export: 'equal_loudness_filter']
pub fn equal_loudness_filter(v &i64,n usize) i64 {
 if unsafe{v==nil}||n<1||n>33{return -1};count:=unsafe{v[0]};if count<0||count>32||n!=usize(count+1){return -1}
 mut x:=[]i64{len:10};mut y:=[]i64{len:10};mut hx:=[]i64{len:2};mut hy:=[]i64{len:2};mut output:=i64(0)
 for i in 0..int(count){sample:=unsafe{v[i+1]};if sample < -1000000||sample>1000000{return -1};mid:=step(sample,false,10,mut x,mut y);output=step(mid,true,2,mut hx,mut hy)}
 return output
}
