package monotonic_array
@(export)
monotonic_array :: proc "c" (v: [^]i64, n: u64) -> i64 {
 if n>256||(v==nil&&n>0) do return -1
 inc,dec:=true,true
 for i:=u64(0);i<n;i+=1{if v[i]<-1000000000||v[i]>1000000000 do return -1}
 for i:=u64(1);i<n;i+=1{if v[i-1]>v[i] do inc=false;if v[i-1]<v[i] do dec=false}
 if inc||dec do return 1
 return 0
}
