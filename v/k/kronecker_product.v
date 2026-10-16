module kronecker_product
@[export: 'kronecker_product']
pub fn kronecker_product(v &i64,n usize)i64{if n!=6{return -1};for i in 0..6{x:=unsafe{v[i]};if x < -10||x>10{return -1}};x:=[8]i64{unsafe{v[0]*v[4]},unsafe{v[0]*v[5]},unsafe{v[1]*v[4]},unsafe{v[1]*v[5]},unsafe{v[2]*v[4]},unsafe{v[2]*v[5]},unsafe{v[3]*v[4]},unsafe{v[3]*v[5]}};mut r:=i64(0);for z in x{r=r*201+z+100};return r}
