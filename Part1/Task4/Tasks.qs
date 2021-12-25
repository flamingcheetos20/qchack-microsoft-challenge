namespace QCHack.Task4 {
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;

    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Measurement;

    // Task 4 (12 points). f(x) = 1 if the graph edge coloring is triangle-free
    // 
    // Inputs:
    //      1) The number of vertices in the graph "V" (V ≤ 6).
    //      2) An array of E tuples of integers "edges", representing the edges of the graph (0 ≤ E ≤ V(V-1)/2).
    //         Each tuple gives the indices of the start and the end vertices of the edge.
    //         The vertices are indexed 0 through V - 1.
    //         The graph is undirected, so the order of the start and the end vertices in the edge doesn't matter.
    //      3) An array of E qubits "colorsRegister" that encodes the color assignments of the edges.
    //         Each color will be 0 or 1 (stored in 1 qubit).
    //         The colors of edges in this array are given in the same order as the edges in the "edges" array.
    //      4) A qubit "target" in an arbitrary state.
    //
    // Goal: Implement a marking oracle for function f(x) = 1 if
    //       the coloring of the edges of the given graph described by this colors assignment is triangle-free, i.e.,
    //       no triangle of edges connecting 3 vertices has all three edges in the same color.
    //
    // Example: a graph with 3 vertices and 3 edges [(0, 1), (1, 2), (2, 0)] has one triangle.
    // The result of applying the operation to state (|001⟩ + |110⟩ + |111⟩)/√3 ⊗ |0⟩ 
    // will be 1/√3|001⟩ ⊗ |1⟩ + 1/√3|110⟩ ⊗ |1⟩ + 1/√3|111⟩ ⊗ |0⟩.
    // The first two terms describe triangle-free colorings, 
    // and the last term describes a coloring where all edges of the triangle have the same color.
    //
    // In this task you are not allowed to use quantum gates that use more qubits than the number of edges in the graph,
    // unless there are 3 or less edges in the graph. For example, if the graph has 4 edges, you can only use 4-qubit gates or less.
    // You are guaranteed that in tests that have 4 or more edges in the graph the number of triangles in the graph 
    // will be strictly less than the number of edges.
    //
    // Hint: Make use of helper functions and helper operations, and avoid trying to fit the complete
    //       implementation into a single operation - it's not impossible but make your code less readable.
    //       GraphColoring kata has an example of implementing oracles for a similar task.
    //
    // Hint: Remember that you can examine the inputs and the intermediary results of your computations
    //       using Message function for classical values and DumpMachine for quantum states.
    //
    operation Task4_TriangleFreeColoringOracle (
        V : Int, 
        edges : (Int, Int)[], 
        colorsRegister : Qubit[], 
        target : Qubit
    ) : Unit is Adj+Ctl {
        // Core Implementation

        if Length(edges) > 0 {
            // Store all triangles and the number of triangles
            let (triangles, TriangleNumber) = allTriangles(V, edges);

            // Allocate array of qubits of size TriangleNumber, each qubit will indicate if a given triangle has all edges of same color
            use ancilla = Qubit[TriangleNumber];

            within {
                // Iterate over all triangles
                for i in 0 .. (TriangleNumber - 1) {
                    let (e0, e1, e2) = triangles[i]; // gives the tuple of edges' indices representing triangle i
                    if e0 > 0 or e1 > 0 or e2 > 0 {
                        // want to access the corresponding colors of the above edges, and track if they are the same color by 
                        // applying operation defined below "TriangleSameColor", and writing result to the ith qubit of ancilla
                        TriangleSameColor([colorsRegister[e0], colorsRegister[e1], colorsRegister[e2]], ancilla[i]);
                    }
                }
            } apply {
                // if the graph is triangle free, the ancilla should be |00...0⟩ - only flip target if this is the case
                (ControlledOnInt(0, X))(ancilla, target);
            }
        } else {
            X(target);
        }
    }

    operation TriangleSameColor (inputs : Qubit[], output : Qubit) : Unit is Adj+Ctl {
        // use same01 = Qubit();
        // use same12 = Qubit();
        // use same20 = Qubit();
        // within {
        //     CX(inputs[0], same01);
        //     CX(inputs[1], same01);

        //     CX(inputs[1], same12);
        //     CX(inputs[2], same12);

        //     CX(inputs[2], same20);
        //     CX(inputs[0], same20);

        //     X(same01);
        //     X(same12);
        // } apply {
        //     (Controlled X)([same01, same12], output);
        // }

        within {
            CNOT(inputs[1], inputs[0]);
            CNOT(inputs[1], inputs[2]);
        } apply {
            Controlled X([inputs[0], inputs[2]], output);
            CNOT(inputs[0], output);
            CNOT(inputs[2], output);
        }
        X(output);

    }

    // identical tuple predicate
    function check (tuple1: (Int, Int), tuple2: (Int, Int)) : Bool {
        let (a, b) = tuple1;
        let (c, d) = tuple2;
        return a == c and b == d;
    }

    // returns list of tuples (i, j, k), where edges[i], edges[j], edges[k] form a triangle
    function allTriangles ( V : Int, edges : (Int, Int)[]) : ((Int, Int, Int)[], Int) {
        mutable triangles = new (Int, Int, Int)[Length(edges)];
        mutable triN = 0; // counts number of valid triangles

        // iterate over all unique triples of vertices
        for v0 in 0 .. (V - 1) {
            for v1 in (v0 + 1) .. (V - 1) {
                for v2 in (v1 + 1) .. (V - 1) {
                    
                    // tuple predicates
                    let isEqual01 = check((v0, v1), _);
                    let isEqual10 = check((v1, v0), _);

                    let isEqual12 = check((v1, v2), _);
                    let isEqual21 = check((v2, v1), _);

                    let isEqual20 = check((v2, v0), _);
                    let isEqual02 = check((v0, v2), _);
                    
                    // indices of triangle edges
                    let i = Max([IndexOf(isEqual01, edges), IndexOf(isEqual10, edges)]);
                    let j = Max([IndexOf(isEqual12, edges), IndexOf(isEqual21, edges)]);
                    let k = Max([IndexOf(isEqual20, edges), IndexOf(isEqual02, edges)]);
                    
                    // insert triangle edge indices if triangle exists
                    if i >= 0 and j >= 0 and k >= 0 {
                        set triangles w/= triN <- (i, j, k);
                        set triN += 1;
                    } 
                }
            }
        }
        return (triangles, triN);
    }

}

