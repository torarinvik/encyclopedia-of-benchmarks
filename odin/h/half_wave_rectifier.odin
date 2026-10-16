package half_wave_rectifier
import "core:c"
BAD :: f64 = -1.0e300
@(export)
half_wave_rectifier :: proc "c" (a:[^]i64,n:c.size_t)->f64{if a==nil||n!=5 do return BAD;for i:=c.size_t(1);i<5;i+=1{if a[i]<-1_000_000||a[i]>1_000_000 do return BAD};switch a[0]{case 0:if a[1]<0||a[2]<0||a[3]<0||(a[1]==0&&a[2]==0&&a[3]==0)do return BAD;return f64(a[4])/f64(a[1]+a[2]+a[3]);case 1,2:if a[2]!=0||a[3]!=0||a[4]!=0 do return BAD;return f64(a[1])*0.318;case 3:if a[2]<=0||a[3]!=0||a[4]!=0 do return BAD;return f64(a[1])/f64(a[2]);case 4,5:if a[2]!=0||a[3]!=0||a[4]!=0 do return BAD;return f64(a[1])/2.0;case:return BAD}}
