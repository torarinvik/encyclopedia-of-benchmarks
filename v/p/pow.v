module pow_benchmark
@[export: 'pow_algorithm']
pub fn pow_algorithm(v &i64,n usize) f64{
 unsafe{if v==nil||n!=2||v[0]<-1000||v[0]>1000||v[1]<-8||v[1]>12{return -1.0e300};mut result:=1.0;for i:=i64(1);i<=v[1];i++{result*=f64(v[0])};return result}
}
