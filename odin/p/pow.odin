package pow_benchmark
import "core:c"
@(export)
pow_algorithm :: proc "c" (v:[^]i64,n:c.size_t)->f64{
 if v==nil||n!=2||v[0]<-1000||v[0]>1000||v[1]<-8||v[1]>12 do return -1.0e300
 result:=1.0
 for i:=i64(1);i<=v[1];i+=1{result*=f64(v[0])}
 return result
}
