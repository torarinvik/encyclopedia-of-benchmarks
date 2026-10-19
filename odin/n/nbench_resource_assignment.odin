package nbench_resource_assignment
import "core:c"
MAX_N :: 8
CELLS :: 64
MAX_ADJUST :: 2048
first_assignments :: proc "contextless" (a: ^[CELLS]i64, mark: ^[CELLS]u8, n: int) -> int {
	for x:=0;x<n*n;x+=1{mark[x]=0};total:=0
	for{made:=0
		for i:=0;i<n;i+=1{cnt,selected:=0,0;for j:=0;j<n;j+=1{if a[i*n+j]==0&&mark[i*n+j]==0{cnt+=1;selected=j}};if cnt==1{made+=1;total+=1;mark[i*n+selected]=1;for k:=0;k<n;k+=1{if k!=i&&a[k*n+selected]==0{mark[k*n+selected]=2}}}}
		for j:=0;j<n;j+=1{cnt,selected:=0,0;for i:=0;i<n;i+=1{if a[i*n+j]==0&&mark[i*n+j]==0{cnt+=1;selected=i}};if cnt==1{made+=1;total+=1;mark[selected*n+j]=1;for k:=0;k<n;k+=1{if k!=j&&a[selected*n+k]==0{mark[selected*n+k]=2}}}}
		if made==0{break}
	}
	if total==n{return total};for i:=0;i<n;i+=1{selected:=n;for j:=0;j<n;j+=1{if a[i*n+j]==0&&mark[i*n+j]==0{selected=j;break}};if selected<n{mark[i*n+selected]=1;total+=1;for k:=0;k<n;k+=1{if k!=selected&&a[i*n+k]==0{mark[i*n+k]=2}};for k:=0;k<n;k+=1{if k!=i&&a[k*n+selected]==0{mark[k*n+selected]=2}}}}};return total
}
second_assignments :: proc "contextless" (a:^ [CELLS]i64, mark:^ [CELLS]u8,n:int)->bool{
	rows:[MAX_N]u8;cols:[MAX_N]u8
	for i:=0;i<n;i+=1{has:=false;for j:=0;j<n;j+=1{if mark[i*n+j]==1{has=true;break}};if has{rows[i]=0}else{rows[i]=1}}
	for{new_rows:=0;for i:=0;i<n;i+=1{if rows[i]==1{for j:=0;j<n;j+=1{if a[i*n+j]==0{cols[j]=1}}}};for j:=0;j<n;j+=1{if cols[j]==1{for i:=0;i<n;i+=1{if mark[i*n+j]==1&&rows[i]!=1{rows[i]=1;new_rows+=1}}}};if new_rows==0{break}}
	smallest:=i64(9223372036854775807);for i:=0;i<n;i+=1{if rows[i]==1{for j:=0;j<n;j+=1{if cols[j]==0&&a[i*n+j]<smallest{smallest=a[i*n+j]}}}};if smallest==i64(9223372036854775807){return false}
	for i:=0;i<n;i+=1{for j:=0;j<n;j+=1{if rows[i]==1&&cols[j]==0{a[i*n+j]-=smallest}else if rows[i]==0&&cols[j]==1{a[i*n+j]+=smallest}}};return true
}
@(export)
nbench_resource_assignment :: proc "c" (values:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if values==nil||length<2||length>c.size_t(CELLS+2) do return -1;raw:=values[0];if raw<1||raw>MAX_N do return -1;n:=int(raw);if length!=c.size_t(1+n*n) do return -1
	a:[CELLS]i64;for i:=0;i<n*n;i+=1{x:=values[i+1];if x<0||x>1000 do return -1;a[i]=x}
	for i:=0;i<n;i+=1{m:=a[i*n];for j:=1;j<n;j+=1{if a[i*n+j]<m do m=a[i*n+j]};for j:=0;j<n;j+=1{a[i*n+j]-=m}}
	for j:=0;j<n;j+=1{m:=a[j];for i:=1;i<n;i+=1{if a[i*n+j]<m do m=a[i*n+j]};if m!=0{for i:=0;i<n;i+=1{a[i*n+j]-=m}}}
	mark:[CELLS]u8;done:=false;for iter:=0;iter<=MAX_ADJUST;iter+=1{if first_assignments(&a,&mark,n)==n{done=true;break};if !second_assignments(&a,&mark,n) do return -1};if !done do return -1
	cols:[MAX_N]int;seen:[MAX_N]bool;for i:=0;i<n;i+=1{col:=n;for j:=0;j<n;j+=1{if mark[i*n+j]==1{if col!=n do return -1;col=j}};if col==n||seen[col] do return -1;cols[i]=col;seen[col]=true}
	bytes:=n*4;if output==nil||capacity<c.size_t(bytes) do return -2;for i:=0;i<n;i+=1{x:=u32(cols[i]);for b:=0;b<4;b+=1{output[4*i+b]=u8((x>>u32(8*b))&255)}};return i64(bytes)
}
