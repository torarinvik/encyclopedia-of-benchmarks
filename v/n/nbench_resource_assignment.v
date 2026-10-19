module nbench_resource_assignment
const nmax=8
const cells=64
const max_adjust=2048
fn first_assignments(mut a [cells]i64, mut mark [cells]u8, n int) int {
	for x in 0 .. n*n { mark[x]=0 }
	mut total:=0
	for {
		mut made:=0
		for i in 0 .. n {
			mut count:=0;mut selected:=0
			for j in 0 .. n { if a[i*n+j]==0 && mark[i*n+j]==0 {count++;selected=j} }
			if count==1 {made++;total++;mark[i*n+selected]=1;for k in 0 .. n {if k!=i&&a[k*n+selected]==0{mark[k*n+selected]=2}}}
		}
		for j in 0 .. n {
			mut count:=0;mut selected:=0
			for i in 0 .. n {if a[i*n+j]==0&&mark[i*n+j]==0{count++;selected=i}}
			if count==1 {made++;total++;mark[selected*n+j]=1;for k in 0 .. n {if k!=j&&a[selected*n+k]==0{mark[selected*n+k]=2}}}
		}
		if made==0 {break}
	}
	if total==n{return total}
	for i in 0 .. n {mut selected:=n;for j in 0 .. n {if a[i*n+j]==0&&mark[i*n+j]==0{selected=j;break}};if selected<n{mark[i*n+selected]=1;total++;for k in 0 .. n{if k!=selected&&a[i*n+k]==0{mark[i*n+k]=2}};for k in 0 .. n{if k!=i&&a[k*n+selected]==0{mark[k*n+selected]=2}}}}
	return total
}
fn second_assignments(mut a [cells]i64, mark [cells]u8, n int) bool {
	mut rows:=[nmax]u8{};mut cols:=[nmax]u8{}
	for i in 0 .. n {mut has:=false;for j in 0 .. n{if mark[i*n+j]==1{has=true;break}};rows[i]=if has{u8(0)}else{u8(1)}}
	for {mut new_rows:=0;for i in 0 .. n{if rows[i]==1{for j in 0 .. n{if a[i*n+j]==0{cols[j]=1}}}};for j in 0 .. n{if cols[j]==1{for i in 0 .. n{if mark[i*n+j]==1&&rows[i]!=1{rows[i]=1;new_rows++}}}};if new_rows==0{break}}
	mut smallest:=i64(0x7fffffffffffffff)
	for i in 0 .. n {if rows[i]==1{for j in 0 .. n{if cols[j]==0&&a[i*n+j]<smallest{smallest=a[i*n+j]}}}}
	if smallest==i64(0x7fffffffffffffff){return false}
	for i in 0 .. n {for j in 0 .. n{if rows[i]==1&&cols[j]==0{a[i*n+j]-=smallest}else if rows[i]==0&&cols[j]==1{a[i*n+j]+=smallest}}}
	return true
}
@[export: 'nbench_resource_assignment']
pub fn nbench_resource_assignment(values &i64,length usize,output &u8,capacity usize)i64{
	unsafe{
		if values==nil||length<2||length>cells+2{return -1};raw:=values[0];if raw<1||raw>nmax{return -1};n:=int(raw);if length!=usize(1+n*n){return -1}
		mut a:=[cells]i64{init:0};for i in 0 .. n*n{x:=values[i+1];if x<0||x>1000{return -1};a[i]=x}
		for i in 0 .. n{mut m:=a[i*n];for j in 1 .. n{if a[i*n+j]<m{m=a[i*n+j]}};for j in 0 .. n{a[i*n+j]-=m}}
		for j in 0 .. n{mut m:=a[j];for i in 1 .. n{if a[i*n+j]<m{m=a[i*n+j]}};if m!=0{for i in 0 .. n{a[i*n+j]-=m}}}
		mut mark:=[cells]u8{init:0};mut done:=false
		for _ in 0 .. max_adjust+1{if first_assignments(mut a,mut mark,n)==n{done=true;break};if !second_assignments(mut a,mark,n){return -1}}
		if !done{return -1};mut cols:=[nmax]int{init:0};mut seen:=[nmax]bool{init:false}
		for i in 0 .. n{mut col:=n;for j in 0 .. n{if mark[i*n+j]==1{if col!=n{return -1};col=j}};if col==n||seen[col]{return -1};cols[i]=col;seen[col]=true}
		bytes:=n*4;if output==nil||capacity<usize(bytes){return -2};for i in 0 .. n{x:=u32(cols[i]);for b in 0 .. 4{output[4*i+b]=u8((x>>u32(8*b))&255)}};return i64(bytes)
	}
}
