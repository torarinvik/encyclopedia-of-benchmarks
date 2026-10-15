module k_nearest_neighbors_binary

const max_dim = 8
const max_points = 128

@[export: 'k_nearest_neighbors_binary']
pub fn k_nearest_neighbors_binary(input &i64,length usize,mut output &u8,capacity usize)i64{
	if unsafe{input==nil}||length<3{return -1}
	unsafe{
		d64,n64,k64:=input[0],input[1],input[2]
		if d64<1||d64>max_dim||n64<1||n64>max_points||k64<1||k64>n64||k64%2==0||length!=usize(3+d64+n64*(d64+1)){return -1}
		d,n,k:=int(d64),int(n64),int(k64)
		for axis in 0..d{if input[3+axis]< -1000||input[3+axis]>1000{return -1}}
		mut distances:=[max_points]i64{};mut labels:=[max_points]i64{}
		for point in 0..n{base:=3+d+point*(d+1);mut distance:=i64(0)
			for axis in 0..d{x:=input[base+axis];if x< -1000||x>1000{return -1};delta:=x-input[3+axis];distance+=delta*delta}
			label:=input[base+d];if label!=0&&label!=1{return -1}
			for prev in 0..point{if distances[prev]==distance{return -1}};distances[point]=distance;labels[point]=label
		}
		for i in 1..n{distance,label:=distances[i],labels[i];mut j:=i;for j>0&&distances[j-1]>distance{distances[j]=distances[j-1];labels[j]=labels[j-1];j--};distances[j]=distance;labels[j]=label}
		mut ones:=i64(0);for i in 0..k{ones+=labels[i]};prediction:=i64(0);if ones>i64(k/2){prediction=1}
		if output==nil||capacity<8{return -2};bits:=u64(prediction);for byte in 0..8{output[byte]=u8(bits>>(8*byte))};return 8
	}
}
