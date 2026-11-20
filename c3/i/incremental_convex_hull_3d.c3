module incremental_convex_hull_3d;

const usz POINT_CAPACITY = 6;
const usz FACE_CAPACITY = 64;
const usz EDGE_CAPACITY = 3 * FACE_CAPACITY;

fn long side_of_face(long* points, usz a, usz b, usz c, usz point) {
    long abx = points[3*b] - points[3*a], aby = points[3*b+1] - points[3*a+1], abz = points[3*b+2] - points[3*a+2];
    long acx = points[3*c] - points[3*a], acy = points[3*c+1] - points[3*a+1], acz = points[3*c+2] - points[3*a+2];
    long apx = points[3*point] - points[3*a], apy = points[3*point+1] - points[3*a+1], apz = points[3*point+2] - points[3*a+2];
    return (aby*acz-abz*acy)*apx + (abz*acx-abx*acz)*apy + (abx*acy-aby*acx)*apz;
}

fn long center_side(long* points, usz a, usz b, usz c, long[3] center_sum) {
    long abx = points[3*b] - points[3*a], aby = points[3*b+1] - points[3*a+1], abz = points[3*b+2] - points[3*a+2];
    long acx = points[3*c] - points[3*a], acy = points[3*c+1] - points[3*a+1], acz = points[3*c+2] - points[3*a+2];
    long dx = center_sum[0] - 4*points[3*a], dy = center_sum[1] - 4*points[3*a+1], dz = center_sum[2] - 4*points[3*a+2];
    return (aby*acz-abz*acy)*dx + (abz*acx-abx*acz)*dy + (abx*acy-aby*acx)*dz;
}

fn long origin_determinant(long* points, usz a, usz b, usz c) {
    long ax=points[3*a], ay=points[3*a+1], az=points[3*a+2];
    long bx=points[3*b], by=points[3*b+1], bz=points[3*b+2];
    long cx=points[3*c], cy=points[3*c+1], cz=points[3*c+2];
    return ax*(by*cz-bz*cy) + ay*(bz*cx-bx*cz) + az*(bx*cy-by*cx);
}

fn long incremental_convex_hull_3d(long* input, usz length) @export("incremental_convex_hull_3d") {
    if (input == null || length < 1 || length > 20) return -1;
    if (input[0] < 4 || input[0] > 6) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 3*n) return -1;
    long[18] points = zeroed;
    for (usz i=0; i<3*n; i++) {
        if (input[i+1] < -10 || input[i+1] > 10) return -1;
        points[i] = input[i+1];
    }
    for (usz i=0; i<n; i++) for (usz j=i+1; j<n; j++)
        if (points[3*i]==points[3*j] && points[3*i+1]==points[3*j+1] && points[3*i+2]==points[3*j+2]) return -1;
    for (usz i=0; i<n; i++) for (usz j=i+1; j<n; j++) for (usz k=j+1; k<n; k++) for (usz ell=k+1; ell<n; ell++)
        if (side_of_face(&points, i, j, k, ell) == 0) return -1;

    long[3] center_sum = zeroed;
    for (usz i=0; i<4; i++) for (usz axis=0; axis<3; axis++) center_sum[axis] += points[3*i+axis];
    usz[64] face_a = zeroed, face_b = zeroed, face_c = zeroed;
    face_a[0]=0; face_a[1]=0; face_a[2]=0; face_a[3]=1;
    face_b[0]=1; face_b[1]=3; face_b[2]=2; face_b[3]=3;
    face_c[0]=2; face_c[1]=1; face_c[2]=3; face_c[3]=2;
    usz face_count = 4;
    for (usz f=0; f<face_count; f++) if (center_side(&points, face_a[f], face_b[f], face_c[f], center_sum)>0) {
        usz temp=face_b[f]; face_b[f]=face_c[f]; face_c[f]=temp;
    }

    for (usz point=4; point<n; point++) {
        bool[64] visible = zeroed;
        usz visible_count=0;
        for (usz f=0; f<face_count; f++) {
            visible[f]=side_of_face(&points, face_a[f], face_b[f], face_c[f], point)>0;
            if (visible[f]) visible_count++;
        }
        if (visible_count==0) continue;
        usz[192] edge_a = zeroed, edge_b = zeroed;
        usz edge_count=0;
        for (usz f=0; f<face_count; f++) if (visible[f]) {
            edge_a[edge_count]=face_a[f]; edge_b[edge_count]=face_b[f]; edge_count++;
            edge_a[edge_count]=face_b[f]; edge_b[edge_count]=face_c[f]; edge_count++;
            edge_a[edge_count]=face_c[f]; edge_b[edge_count]=face_a[f]; edge_count++;
        }
        usz[64] next_a=zeroed, next_b=zeroed, next_c=zeroed;
        usz next_count=0;
        for (usz f=0; f<face_count; f++) if (!visible[f]) {
            next_a[next_count]=face_a[f]; next_b[next_count]=face_b[f]; next_c[next_count]=face_c[f]; next_count++;
        }
        for (usz e=0; e<edge_count; e++) {
            usz copies=0;
            for (usz other=0; other<edge_count; other++)
                if ((edge_a[e]==edge_a[other] && edge_b[e]==edge_b[other]) || (edge_a[e]==edge_b[other] && edge_b[e]==edge_a[other])) copies++;
            if (copies!=1) continue;
            if (next_count>=FACE_CAPACITY) return -1;
            usz a=edge_a[e], b=edge_b[e], c=point;
            if (center_side(&points, a, b, c, center_sum)>0) { usz temp=b; b=c; c=temp; }
            next_a[next_count]=a; next_b[next_count]=b; next_c[next_count]=c; next_count++;
        }
        for (usz f=0; f<next_count; f++) { face_a[f]=next_a[f]; face_b[f]=next_b[f]; face_c[f]=next_c[f]; }
        face_count=next_count;
    }
    long volume_six=0;
    for (usz f=0; f<face_count; f++) volume_six += origin_determinant(&points, face_a[f], face_b[f], face_c[f]);
    return volume_six;
}
