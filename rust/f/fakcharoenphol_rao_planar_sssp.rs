use std::slice;

const MAX_N: usize = 12;
const MAX_ARCS: usize = 60;
const MAX_PIECES: usize = 119;
const MAX_BOUNDARY: usize = 12;
const MAX_BLOCKS: usize = 44;
const MAX_UNION_NODES: usize = 24;
const MAX_BASE_ARCS: usize = 3;
const MAX_INPUT: usize = 2088;
const MAX_WEIGHT: i64 = 100;
const INF: i64 = 1_i64 << 60;

#[derive(Clone, Copy, Default)]
struct Arc {
    tail: usize,
    head: usize,
    weight: i64,
}

#[derive(Clone, Copy, Default)]
struct Piece {
    left: isize,
    right: isize,
    boundary_count: usize,
    arc_mask: u64,
    vertex_mask: u16,
    boundary: [usize; MAX_BOUNDARY],
}

#[derive(Clone, Copy)]
struct Block {
    child: usize,
    row_count: usize,
    column_count: usize,
    rows: [usize; MAX_BOUNDARY],
    columns: [usize; MAX_BOUNDARY],
    weights: [[i64; MAX_BOUNDARY]; MAX_BOUNDARY],
    best_value: [i64; MAX_BOUNDARY],
    best_row: [usize; MAX_BOUNDARY],
}

impl Default for Block {
    fn default() -> Self {
        Self {
            child: 0,
            row_count: 0,
            column_count: 0,
            rows: [0; MAX_BOUNDARY],
            columns: [0; MAX_BOUNDARY],
            weights: [[INF; MAX_BOUNDARY]; MAX_BOUNDARY],
            best_value: [INF; MAX_BOUNDARY],
            best_row: [usize::MAX; MAX_BOUNDARY],
        }
    }
}

struct Context {
    n: usize,
    m: usize,
    source: usize,
    piece_count: usize,
    pieces: [Piece; MAX_PIECES],
    arcs: [Arc; MAX_ARCS],
    ddg: [[[i64; MAX_N]; MAX_N]; MAX_PIECES],
    potential: [[i64; MAX_N]; MAX_PIECES],
    blocks: [Block; MAX_BLOCKS],
}

impl Context {
    fn new() -> Self {
        Self {
            n: 0,
            m: 0,
            source: 0,
            piece_count: 0,
            pieces: [Piece::default(); MAX_PIECES],
            arcs: [Arc::default(); MAX_ARCS],
            ddg: [[[INF; MAX_N]; MAX_N]; MAX_PIECES],
            potential: [[0; MAX_N]; MAX_PIECES],
            blocks: [Block::default(); MAX_BLOCKS],
        }
    }

    fn parse(&mut self, input: &[i64]) -> bool {
        if input.len() < 4 || input.len() > MAX_INPUT {
            return false;
        }
        let (n_value, m_value, source_value, pieces_value) =
            (input[0], input[1], input[2], input[3]);
        if !(2..=MAX_N as i64).contains(&n_value)
            || !(1..=MAX_ARCS as i64).contains(&m_value)
            || source_value < 0
            || source_value >= n_value
            || pieces_value < 1
            || pieces_value > MAX_PIECES as i64
            || pieces_value % 2 == 0
        {
            return false;
        }
        self.n = n_value as usize;
        self.m = m_value as usize;
        self.source = source_value as usize;
        self.piece_count = pieces_value as usize;

        let mut seen_arc = [[false; MAX_N]; MAX_N];
        let mut seen_pair = [[false; MAX_N]; MAX_N];
        let mut undirected_edges = 0usize;
        let mut offset = 4usize;
        for edge in 0..self.m {
            if offset + 3 > input.len() {
                return false;
            }
            let (u_value, v_value, weight) =
                (input[offset], input[offset + 1], input[offset + 2]);
            offset += 3;
            if u_value < 0
                || u_value >= self.n as i64
                || v_value < 0
                || v_value >= self.n as i64
                || u_value == v_value
                || !(-MAX_WEIGHT..=MAX_WEIGHT).contains(&weight)
            {
                return false;
            }
            let (u, v) = (u_value as usize, v_value as usize);
            if seen_arc[u][v] {
                return false;
            }
            seen_arc[u][v] = true;
            if !seen_pair[u][v] {
                seen_pair[u][v] = true;
                seen_pair[v][u] = true;
                undirected_edges += 1;
            }
            self.arcs[edge] = Arc { tail: u, head: v, weight };
        }
        let simple_edge_limit = if self.n == 2 { 1 } else { 3 * self.n - 6 };
        if undirected_edges > simple_edge_limit || self.m > 2 * simple_edge_limit {
            return false;
        }

        let mut visited = [false; MAX_N];
        let mut queue = [0usize; MAX_N];
        let (mut head, mut tail) = (0usize, 0usize);
        visited[0] = true;
        queue[tail] = 0;
        tail += 1;
        while head < tail {
            let u = queue[head];
            head += 1;
            for edge in 0..self.m {
                let (a, b) = (self.arcs[edge].tail, self.arcs[edge].head);
                let v = if a == u { Some(b) } else if b == u { Some(a) } else { None };
                if let Some(v) = v {
                    if !visited[v] {
                        visited[v] = true;
                        queue[tail] = v;
                        tail += 1;
                    }
                }
            }
        }
        if visited[..self.n].iter().any(|&seen| !seen) {
            return false;
        }

        let mut parent_count = [0usize; MAX_PIECES];
        let mut leaf_union = 0u64;
        let mut leaf_count = 0usize;
        let full_arc_mask = (1u64 << self.m) - 1;
        for index in 0..self.piece_count {
            if offset + 4 > input.len() {
                return false;
            }
            let (left_value, right_value, mask_value, boundary_count_value) = (
                input[offset], input[offset + 1], input[offset + 2], input[offset + 3],
            );
            offset += 4;
            if boundary_count_value < 1
                || boundary_count_value > MAX_BOUNDARY as i64
                || boundary_count_value > self.n as i64
                || offset + boundary_count_value as usize > input.len()
            {
                return false;
            }
            let mut piece = Piece::default();
            piece.boundary_count = boundary_count_value as usize;
            let mut listed_boundary = 0u16;
            for i in 0..piece.boundary_count {
                let vertex_value = input[offset];
                offset += 1;
                if vertex_value < 0 || vertex_value >= self.n as i64 {
                    return false;
                }
                let vertex = vertex_value as usize;
                let bit = 1u16 << vertex;
                if listed_boundary & bit != 0 {
                    return false;
                }
                listed_boundary |= bit;
                piece.boundary[i] = vertex;
            }

            if left_value == -1 && right_value == -1 {
                if mask_value <= 0 {
                    return false;
                }
                let mask = mask_value as u64;
                if mask & !full_arc_mask != 0
                    || mask.count_ones() as usize > MAX_BASE_ARCS
                    || leaf_union & mask != 0
                {
                    return false;
                }
                piece.left = -1;
                piece.right = -1;
                piece.arc_mask = mask;
                leaf_union |= mask;
                leaf_count += 1;
                piece.vertex_mask = self.vertex_mask_for_arcs(mask);
                if !self.piece_connected(mask, piece.vertex_mask) {
                    return false;
                }
            } else {
                if left_value < 0
                    || right_value < 0
                    || left_value >= index as i64
                    || right_value >= index as i64
                    || left_value == right_value
                    || mask_value != -1
                {
                    return false;
                }
                let (left, right) = (left_value as usize, right_value as usize);
                if parent_count[left] != 0 || parent_count[right] != 0 {
                    return false;
                }
                parent_count[left] = 1;
                parent_count[right] = 1;
                let left_piece = self.pieces[left];
                let right_piece = self.pieces[right];
                if left_piece.arc_mask & right_piece.arc_mask != 0 {
                    return false;
                }
                piece.left = left as isize;
                piece.right = right as isize;
                piece.arc_mask = left_piece.arc_mask | right_piece.arc_mask;
                piece.vertex_mask = left_piece.vertex_mask | right_piece.vertex_mask;
                let parent_vertices = piece.vertex_mask.count_ones() as usize;
                let max_child_vertices = (2 * parent_vertices + 2) / 3;
                if left_piece.vertex_mask.count_ones() as usize > max_child_vertices
                    || right_piece.vertex_mask.count_ones() as usize > max_child_vertices
                    || left_piece.vertex_mask & right_piece.vertex_mask == 0
                {
                    return false;
                }
            }

            let piece_mask = piece.vertex_mask;
            let piece_arcs = piece.arc_mask;
            let mut expected_boundary = 0u16;
            for vertex in 0..self.n {
                let bit = 1u16 << vertex;
                if piece_mask & bit == 0 {
                    continue;
                }
                if vertex == self.source {
                    expected_boundary |= bit;
                    continue;
                }
                for edge in 0..self.m {
                    if piece_arcs & (1u64 << edge) == 0
                        && (self.arcs[edge].tail == vertex || self.arcs[edge].head == vertex)
                    {
                        expected_boundary |= bit;
                        break;
                    }
                }
            }
            if listed_boundary != expected_boundary || !self.piece_connected(piece_arcs, piece_mask) {
                return false;
            }
            if index == self.piece_count - 1
                && (piece_arcs != full_arc_mask || piece_mask != ((1u16 << self.n) - 1))
            {
                return false;
            }
            self.pieces[index] = piece;
        }
        if offset != input.len()
            || leaf_count == 0
            || self.piece_count != 2 * leaf_count - 1
            || leaf_union != full_arc_mask
            || parent_count[self.piece_count - 1] != 0
        {
            return false;
        }
        if parent_count[..self.piece_count - 1].iter().any(|&count| count != 1) {
            return false;
        }
        let root = self.pieces[self.piece_count - 1];
        root.boundary_count == 1 && root.boundary[0] == self.source
    }

    fn execute(&mut self, output: *mut u8, capacity: usize) -> i64 {
        let mut nodes = [0usize; MAX_N];
        for (vertex, slot) in nodes.iter_mut().take(self.n).enumerate() {
            *slot = vertex;
        }
        let mut global_potential = [0i64; MAX_N];
        if !bellman_ford_all(&nodes[..self.n], &self.arcs[..self.m], &mut global_potential) {
            return -1;
        }
        for piece in 0..self.piece_count {
            self.ddg[piece] = [[INF; MAX_N]; MAX_N];
        }
        for piece in 0..self.piece_count {
            if self.build_piece(piece) != 0 {
                return -1;
            }
        }

        let mut result = [INF; MAX_N];
        let mut known = [INF; MAX_N];
        known[self.source] = 0;
        self.expand(self.piece_count - 1, &known, &mut result);
        let output_bytes = self.n * 8;
        if output.is_null() || capacity < output_bytes {
            return -2;
        }
        for (vertex, &distance) in result.iter().enumerate().take(self.n) {
            let value = if distance == INF { i64::MAX } else { distance };
            let bytes = value.to_le_bytes();
            unsafe {
                for (offset, byte) in bytes.iter().enumerate() {
                    output.add(vertex * 8 + offset).write(*byte);
                }
            }
        }
        output_bytes as i64
    }

    fn vertex_mask_for_arcs(&self, mask: u64) -> u16 {
        let mut result = 0u16;
        for edge in 0..self.m {
            if mask & (1u64 << edge) != 0 {
                result |= (1u16 << self.arcs[edge].tail) | (1u16 << self.arcs[edge].head);
            }
        }
        result
    }

    fn piece_connected(&self, mask: u64, vertex_mask: u16) -> bool {
        if vertex_mask == 0 {
            return false;
        }
        let start = (0..self.n).find(|&v| vertex_mask & (1u16 << v) != 0).unwrap_or(self.n);
        if start == self.n {
            return false;
        }
        let mut reached = 1u16 << start;
        let mut changed = true;
        while changed {
            changed = false;
            for edge in 0..self.m {
                if mask & (1u64 << edge) == 0 {
                    continue;
                }
                let (u, v) = (self.arcs[edge].tail, self.arcs[edge].head);
                let (ub, vb) = (1u16 << u, 1u16 << v);
                if reached & ub != 0 && reached & vb == 0 {
                    reached |= vb;
                    changed = true;
                }
                if reached & vb != 0 && reached & ub == 0 {
                    reached |= ub;
                    changed = true;
                }
            }
        }
        reached == vertex_mask
    }

    fn collect_arcs(&self, mask: u64, out: &mut [Arc; MAX_BASE_ARCS]) -> usize {
        let mut count = 0;
        for edge in 0..self.m {
            if mask & (1u64 << edge) != 0 {
                out[count] = self.arcs[edge];
                count += 1;
            }
        }
        count
    }

    fn build_piece(&mut self, index: usize) -> i32 {
        self.ddg[index] = [[INF; MAX_N]; MAX_N];
        let piece = self.pieces[index];
        if piece.left == -1 {
            let mut local_arcs = [Arc::default(); MAX_BASE_ARCS];
            let arc_count = self.collect_arcs(piece.arc_mask, &mut local_arcs);
            let mut nodes = [0usize; MAX_N];
            let mut node_count = 0;
            for vertex in 0..self.n {
                if piece.vertex_mask & (1u16 << vertex) != 0 {
                    nodes[node_count] = vertex;
                    node_count += 1;
                }
            }
            let mut local_potential = [0i64; MAX_N];
            if !bellman_ford_all(&nodes[..node_count], &local_arcs[..arc_count], &mut local_potential) {
                return -1;
            }
            for i in 0..piece.boundary_count {
                let mut seeds = [INF; MAX_N];
                let mut labels = [INF; MAX_N];
                seeds[piece.boundary[i]] = 0;
                if !bellman_ford_seeded(self.n, &local_arcs[..arc_count], &seeds, &mut labels) {
                    return -1;
                }
                for j in 0..piece.boundary_count {
                    self.ddg[index][piece.boundary[i]][piece.boundary[j]] = labels[piece.boundary[j]];
                }
            }
            return 0;
        }

        let left = piece.left as usize;
        let right = piece.right as usize;
        let mut nodes = [0usize; MAX_UNION_NODES];
        let node_count = self.unique_child_nodes(left, right, &mut nodes);
        let mut in_union = [false; MAX_N];
        for &vertex in &nodes[..node_count] {
            in_union[vertex] = true;
        }
        if piece.boundary[..piece.boundary_count].iter().any(|&v| !in_union[v]) {
            return -1;
        }

        let mut union_arcs = [Arc::default(); 2 * MAX_BOUNDARY * MAX_BOUNDARY];
        let mut union_arc_count = 0usize;
        for child in [left, right] {
            let child_piece = self.pieces[child];
            for i in 0..child_piece.boundary_count {
                for j in 0..child_piece.boundary_count {
                    let (u, v) = (child_piece.boundary[i], child_piece.boundary[j]);
                    let weight = self.ddg[child][u][v];
                    if u != v && weight != INF {
                        union_arcs[union_arc_count] = Arc { tail: u, head: v, weight };
                        union_arc_count += 1;
                    }
                }
            }
        }
        let mut potential = [0i64; MAX_N];
        if !bellman_ford_all(&nodes[..node_count], &union_arcs[..union_arc_count], &mut potential) {
            return -1;
        }
        for arc in &union_arcs[..union_arc_count] {
            if arc.weight + potential[arc.tail] - potential[arc.head] < 0 {
                return -1;
            }
        }
        self.potential[index] = potential;

        for child in [left, right] {
            if !self.check_monge_rec(child, 0, self.pieces[child].boundary_count) {
                return -1;
            }
        }
        let mut block_count = 0usize;
        for child in [left, right] {
            self.build_blocks_rec(child, 0, self.pieces[child].boundary_count, &potential, &mut block_count);
        }
        for i in 0..piece.boundary_count {
            let start = piece.boundary[i];
            let labels = run_dijkstra(
                &nodes[..node_count],
                &mut self.blocks,
                block_count,
                &[start],
                &[0],
            );
            for j in 0..piece.boundary_count {
                let target = piece.boundary[j];
                let value = labels[target];
                self.ddg[index][start][target] = if value == INF {
                    INF
                } else {
                    value - potential[start] + potential[target]
                };
            }
        }
        0
    }

    fn unique_child_nodes(&self, left: usize, right: usize, nodes: &mut [usize; MAX_UNION_NODES]) -> usize {
        let mut present = [false; MAX_N];
        for child in [left, right] {
            let piece = self.pieces[child];
            for &vertex in &piece.boundary[..piece.boundary_count] {
                present[vertex] = true;
            }
        }
        let mut count = 0;
        for (vertex, &is_present) in present.iter().enumerate().take(self.n) {
            if is_present {
                nodes[count] = vertex;
                count += 1;
            }
        }
        count
    }

    fn check_monge_rec(&self, piece_index: usize, lo: usize, hi: usize) -> bool {
        if hi - lo <= 1 {
            return true;
        }
        let piece = self.pieces[piece_index];
        let middle = (lo + hi) / 2;
        for direction in 0..2 {
            let (row_lo, row_hi, col_lo, col_hi) = if direction == 0 {
                (lo, middle, middle, hi)
            } else {
                (middle, hi, lo, middle)
            };
            for i in row_lo..row_hi {
                for i2 in i + 1..row_hi {
                    for j in col_lo..col_hi {
                        for j2 in j + 1..col_hi {
                            let (u, u2) = (piece.boundary[i], piece.boundary[i2]);
                            let (v, v2) = (piece.boundary[j], piece.boundary[j2]);
                            let lhs = monge_sum(self.ddg[piece_index][u][v], self.ddg[piece_index][u2][v2]);
                            let rhs = monge_sum(self.ddg[piece_index][u][v2], self.ddg[piece_index][u2][v]);
                            if lhs > rhs {
                                return false;
                            }
                        }
                    }
                }
            }
        }
        self.check_monge_rec(piece_index, lo, middle)
            && self.check_monge_rec(piece_index, middle, hi)
    }

    fn add_block(
        &mut self,
        child: usize,
        rows: &[usize],
        columns: &[usize],
        potential: &[i64; MAX_N],
        block_count: &mut usize,
    ) {
        if rows.is_empty() || columns.is_empty() || *block_count >= MAX_BLOCKS {
            return;
        }
        let mut block = Block::default();
        block.child = child;
        block.row_count = rows.len();
        block.column_count = columns.len();
        block.rows[..rows.len()].copy_from_slice(rows);
        block.columns[..columns.len()].copy_from_slice(columns);
        for (i, &u) in rows.iter().enumerate() {
            for (j, &v) in columns.iter().enumerate() {
                let distance = self.ddg[child][u][v];
                block.weights[i][j] = if distance == INF {
                    INF
                } else {
                    distance + potential[u] - potential[v]
                };
            }
        }
        self.blocks[*block_count] = block;
        *block_count += 1;
    }

    fn build_blocks_rec(
        &mut self,
        child: usize,
        lo: usize,
        hi: usize,
        potential: &[i64; MAX_N],
        block_count: &mut usize,
    ) {
        if hi - lo <= 1 {
            return;
        }
        let boundary = self.pieces[child].boundary;
        let middle = (lo + hi) / 2;
        self.add_block(child, &boundary[lo..middle], &boundary[middle..hi], potential, block_count);
        self.add_block(child, &boundary[middle..hi], &boundary[lo..middle], potential, block_count);
        self.build_blocks_rec(child, lo, middle, potential, block_count);
        self.build_blocks_rec(child, middle, hi, potential, block_count);
    }

    fn expand(&mut self, index: usize, known: &[i64; MAX_N], result: &mut [i64; MAX_N]) {
        let piece = self.pieces[index];
        if piece.left == -1 {
            let mut local_arcs = [Arc::default(); MAX_BASE_ARCS];
            let arc_count = self.collect_arcs(piece.arc_mask, &mut local_arcs);
            let mut labels = [INF; MAX_N];
            if !bellman_ford_seeded(self.n, &local_arcs[..arc_count], known, &mut labels) {
                return;
            }
            for vertex in 0..self.n {
                if piece.vertex_mask & (1u16 << vertex) != 0 && labels[vertex] < result[vertex] {
                    result[vertex] = labels[vertex];
                }
            }
            return;
        }

        let (left, right) = (piece.left as usize, piece.right as usize);
        let mut nodes = [0usize; MAX_UNION_NODES];
        let node_count = self.unique_child_nodes(left, right, &mut nodes);
        let potential = self.potential[index];
        let mut block_count = 0usize;
        for child in [left, right] {
            let boundary_count = self.pieces[child].boundary_count;
            self.build_blocks_rec(child, 0, boundary_count, &potential, &mut block_count);
        }
        let mut seed_vertices = [0usize; MAX_BOUNDARY];
        let mut seed_values = [0i64; MAX_BOUNDARY];
        let mut seed_count = 0usize;
        for i in 0..piece.boundary_count {
            let vertex = piece.boundary[i];
            if known[vertex] != INF {
                seed_vertices[seed_count] = vertex;
                seed_values[seed_count] = known[vertex] - potential[vertex];
                seed_count += 1;
            }
        }
        let reduced = run_dijkstra(
            &nodes[..node_count],
            &mut self.blocks,
            block_count,
            &seed_vertices[..seed_count],
            &seed_values[..seed_count],
        );
        let mut raw = [INF; MAX_N];
        for vertex in 0..self.n {
            raw[vertex] = if reduced[vertex] == INF { INF } else { reduced[vertex] + potential[vertex] };
        }
        for child in [left, right] {
            let child_piece = self.pieces[child];
            let mut child_known = [INF; MAX_N];
            for &vertex in &child_piece.boundary[..child_piece.boundary_count] {
                child_known[vertex] = raw[vertex];
            }
            self.expand(child, &child_known, result);
        }
    }
}

fn bellman_ford_all(nodes: &[usize], arcs: &[Arc], labels: &mut [i64; MAX_N]) -> bool {
    for &vertex in nodes {
        labels[vertex] = 0;
    }
    for _ in 0..nodes.len().saturating_sub(1) {
        let mut changed = false;
        for arc in arcs {
            let candidate = labels[arc.tail] + arc.weight;
            if candidate < labels[arc.head] {
                labels[arc.head] = candidate;
                changed = true;
            }
        }
        if !changed {
            break;
        }
    }
    arcs.iter().all(|arc| labels[arc.tail] + arc.weight >= labels[arc.head])
}

fn bellman_ford_seeded(
    n: usize,
    arcs: &[Arc],
    seeds: &[i64; MAX_N],
    labels: &mut [i64; MAX_N],
) -> bool {
    *labels = *seeds;
    for _ in 0..n.saturating_sub(1) {
        let mut changed = false;
        for arc in arcs {
            if labels[arc.tail] == INF {
                continue;
            }
            let candidate = labels[arc.tail] + arc.weight;
            if candidate < labels[arc.head] {
                labels[arc.head] = candidate;
                changed = true;
            }
        }
        if !changed {
            break;
        }
    }
    arcs.iter().all(|arc| labels[arc.tail] == INF || labels[arc.tail] + arc.weight >= labels[arc.head])
}

fn monge_sum(a: i64, b: i64) -> i64 {
    if a == INF || b == INF { INF } else { a + b }
}

fn activate(vertex: usize, value: i64, blocks: &mut [Block], block_count: usize, settled: &[bool; MAX_N]) {
    for block in blocks.iter_mut().take(block_count) {
        for i in 0..block.row_count {
            if block.rows[i] != vertex {
                continue;
            }
            for j in 0..block.column_count {
                let target = block.columns[j];
                let weight = block.weights[i][j];
                if settled[target] || weight == INF {
                    continue;
                }
                let candidate = value + weight;
                if candidate < block.best_value[j]
                    || (candidate == block.best_value[j] && vertex < block.best_row[j])
                {
                    block.best_value[j] = candidate;
                    block.best_row[j] = vertex;
                }
            }
        }
    }
}

fn settle(vertex: usize, blocks: &mut [Block], block_count: usize, settled: &mut [bool; MAX_N]) {
    settled[vertex] = true;
    for block in blocks.iter_mut().take(block_count) {
        for j in 0..block.column_count {
            if block.columns[j] == vertex {
                block.best_value[j] = INF;
                block.best_row[j] = usize::MAX;
            }
        }
    }
}

fn run_dijkstra(
    nodes: &[usize],
    blocks: &mut [Block; MAX_BLOCKS],
    block_count: usize,
    seed_vertices: &[usize],
    seed_values: &[i64],
) -> [i64; MAX_N] {
    let mut settled = [false; MAX_N];
    let mut labels = [INF; MAX_N];
    for block in blocks.iter_mut().take(block_count) {
        for j in 0..block.column_count {
            block.best_value[j] = INF;
            block.best_row[j] = usize::MAX;
        }
    }
    for (&vertex, &value) in seed_vertices.iter().zip(seed_values) {
        if value < labels[vertex] {
            labels[vertex] = value;
        }
    }
    for &vertex in nodes {
        if labels[vertex] != INF {
            activate(vertex, labels[vertex], blocks, block_count, &settled);
        }
    }

    loop {
        let mut best_key = (INF, usize::MAX, usize::MAX);
        for &vertex in nodes {
            let value = labels[vertex];
            if !settled[vertex] && value != INF {
                best_key = best_key.min((value, vertex, 0));
            }
        }
        for block in blocks.iter().take(block_count) {
            for j in 0..block.column_count {
                let vertex = block.columns[j];
                let value = block.best_value[j];
                if !settled[vertex] && value != INF {
                    best_key = best_key.min((value, vertex, block.best_row[j] + 1));
                }
            }
        }
        if best_key.1 == usize::MAX {
            break;
        }
        let (value, vertex, _) = best_key;
        if value < labels[vertex] {
            labels[vertex] = value;
        }
        settle(vertex, blocks, block_count, &mut settled);
        activate(vertex, labels[vertex], blocks, block_count, &settled);
    }
    labels
}

#[no_mangle]
pub unsafe extern "C" fn fakcharoenphol_rao_planar_sssp(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT {
        return -1;
    }
    let values = slice::from_raw_parts(input, length);
    let mut context = Context::new();
    if !context.parse(values) {
        return -1;
    }
    context.execute(output, capacity)
}
