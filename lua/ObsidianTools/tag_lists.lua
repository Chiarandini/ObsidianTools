return {
	-- Algebra & Algebraic Structures
	["algebraic geometry"]        = { "mathematics", "algebra", "algebraic_geometry", "geometry", "schemes", "sheaves", "cohomology", "varieties" },
	["commutative algebra"]       = { "mathematics", "algebra", "commutative_algebra", "rings", "ideals", "modules" },
	["homological algebra"]       = { "mathematics", "algebra", "homological_algebra", "cohomology", "derived_categories", "ext_tor" },
	["representation theory"]     = { "mathematics", "algebra", "representation_theory", "group_theory", "lie_theory", "modules" },
	["group_theory"]              = { "mathematics", "algebra", "group_theory", "finite_groups"},
	["ring_theory"]               = { "mathematics", "algebra", "ring_theory", "noncommutative_algebra" },
	["linear_algebra"]            = { "mathematics", "algebra", "linear_algebra", "vector_spaces", "matrices", "eigenvalues" },
	["lie_theory"]                = { "mathematics", "algebra", "differential_geometry", "lie_theory", "lie_groups", "lie_algebras" },

	-- Number Theory & Arithmetic
	["number theory (nt)"]        = { "mathematics", "algebra", "number_theory", "arithmetic", "diophantine" },
	["algebraic number theory"]   = { "mathematics", "algebra", "number_theory", "algebraic_number_theory", "galois_theory", "class_field_theory" },
	["analytic number theory"]    = { "mathematics", "number_theory", "analysis", "analytic_number_theory", "l_functions"},
	["anabelian_geometry"]        = { "mathematics", "algebra", "number_theory", "anabelian_geometry", "galois_theory", "fundamental_groups" },
	["elliptic curves"]           = { "mathematics", "algebra", "number_theory", "algebraic_geometry", "curves", "elliptic_curves", "modular_forms" },
	["modular forms"]             = { "mathematics", "number_theory", "complex_analysis", "modular_forms", "automorphic_forms" },
	["arithmetic geometry"]       = { "mathematics", "algebra", "number_theory", "algebraic_geometry", "arithmetic_geometry", "diophantine" },

	-- Geometry & Topology
	["differential geometry"]     = { "mathematics", "geometry", "differential_geometry", "riemannian_geometry", "symplectic_geometry", "manifolds" },
	["riemannian_geometry"]       = { "mathematics", "geometry", "differential_geometry", "riemannian_geometry", "curvature", "geodesics" },
	["symplectic_geometry"]       = { "mathematics", "geometry", "symplectic_geometry", "hamiltonian_systems", "moment_maps" },
	["algebraic_topology"]        = { "mathematics", "topology", "algebra", "algebraic_topology", "homology", "cohomology", "fundamental_groups" },
	["topology"]                  = { "mathematics", "topology", "point_set_topology" },
	["geometric topology"]        = { "mathematics", "topology", "geometric_topology", "3_manifolds", "4_manifolds" },
	["knot theory"]               = { "mathematics", "topology", "geometric_topology", "knot_theory", "braids", "invariants" },
	["homotopy_theory"]           = { "mathematics", "topology", "algebra", "algebraic_topology", "homotopy_theory", "stable_homotopy", "spectra" },
	["etale"]                     = { "mathematics", "algebra", "algebraic_geometry", "geometry", "algebraic_topology", "etale", "homotopy_theory", "galois_theory", "cohomology" },

	-- Analysis
	["real_analysis"]             = { "mathematics", "analysis", "real_analysis", "measure_theory", "integration", "functional_analysis" },
	["complex_analysis"]          = { "mathematics", "analysis", "complex_analysis", "holomorphic_functions", "riemann_surfaces", "conformal_mapping" },
	["functional_analysis"]       = { "mathematics", "analysis", "functional_analysis", "banach_spaces", "hilbert_spaces", "operator_theory" },
	["harmonic_analysis"]         = { "mathematics", "analysis", "harmonic_analysis", "fourier_analysis", "representation_theory" },
	["measure_theory"]            = { "mathematics", "analysis", "measure_theory", "integration", "probability" },
	["operator_theory"]           = { "mathematics", "analysis", "functional_analysis", "operator_theory", "spectral_theory" },
	["approximation_theory"]      = { "mathematics", "analysis", "approximation_theory", "numerical_analysis" },
	["PDE's"]                     = { "mathematics", "analysis", "differential_equations", "PDE"},
	["ODE's"]                     = { "mathematics", "analysis", "differential_equations", "ODE", "dynamical_systems" },
	["dynamical systems"]         = { "mathematics", "analysis", "dynamical_systems", "chaos_theory", "ergodic_theory" },

	-- Applied Mathematics
	["numerical_analysis"]        = { "mathematics", "applied_mathematics", "numerical_analysis", "computational_mathematics", "algorithms" },
	["optimization"]              = { "mathematics", "applied_mathematics", "optimization", "convex_analysis", "operations_research" },
	["mathematical_physics"]      = { "mathematics", "physics", "mathematical_physics", "quantum_mechanics", "field_theory" },
	["mathematical_biology"]      = { "mathematics", "biology", "applied_mathematics", "mathematical_biology", "population_dynamics" },
	["mathematical_finance"]      = { "mathematics", "finance", "applied_mathematics", "mathematical_finance", "stochastic_processes" },

	-- Probability & Statistics
	["probability theory"]        = { "mathematics", "probability", "measure_theory", "stochastic_processes" },
	["statistics"]                = { "mathematics", "statistics", "probability", "statistical_inference", "data_analysis" },
	["stochastic processes"]      = { "mathematics", "probability", "stochastic_processes", "markov_chains", "martingales" },

	-- Discrete Mathematics
	["combinatorics"]             = { "mathematics", "discrete_mathematics", "combinatorics", "graph_theory", "enumerative" },
	["graph_theory"]              = { "mathematics", "discrete_mathematics", "combinatorics", "graph_theory", "networks" },
	["algebraic_combinatorics"]   = { "mathematics", "algebra", "combinatorics", "algebraic_combinatorics", "symmetric_functions" },
	["discrete_mathematics"]      = { "mathematics", "discrete_mathematics", "combinatorics", "logic", "algorithms" },

	-- Logic & Foundations
	["logic"]                     = { "mathematics", "foundations", "logic", "mathematical_logic", "model_theory", "proof_theory" },
	["set_theory"]                = { "mathematics", "foundations", "set_theory", "axiomatic_set_theory", "forcing" },
	["model_theory"]              = { "mathematics", "foundations", "logic", "model_theory", "structures" },
	["proof_theory"]              = { "mathematics", "foundations", "logic", "proof_theory", "type_theory" },
	["computability theory"]      = { "mathematics", "foundations", "logic", "computability", "recursion_theory" },

	-- Category Theory & Higher Structures
	["category_theory"]           = { "mathematics", "algebra", "category_theory", "functors", "natural_transformations", "topos_theory" },
	["topos_theory"]              = { "mathematics", "algebra", "category_theory", "topos_theory", "sheaves", "logic" },
	["higher_category_theory"]    = { "mathematics", "algebra", "category_theory", "higher_categories", "homotopy_theory" },

	-- Specialized Areas
	["K-Theory"]                  = { "mathematics", "algebra", "topology", "k_theory", "algebraic_k_theory", "topological_k_theory" },
	["vector_bundle"]             = { "mathematics", "algebra", "differential_geometry", "topology", "vector_bundles", "characteristic_classes" },
	["cohomology_theories"]       = { "mathematics", "algebra", "topology", "cohomology"},
	["galois_theory"]             = { "mathematics", "algebra", "field_theory", "galois_theory", "groups" },
	["field_theory"]              = { "mathematics", "algebra", "field_theory", "galois_theory" },

	-- Information & Computation
	["cryptography"]              = { "mathematics", "applied_mathematics", "cryptography", "number_theory", "algorithms" },
	["information_theory"]        = { "mathematics", "applied_mathematics", "information_theory", "entropy", "communication" },
	["game_theory"]               = { "mathematics", "applied_mathematics", "game_theory", "strategy" },
	["computational_mathematics"] = { "mathematics", "applied_mathematics", "computational_mathematics", "algorithms", "complexity" },

	-- History & Philosophy
	["history of mathematics"]    = { "mathematics", "history", "mathematical_history" },
	["philosophy of mathematics"] = { "mathematics", "philosophy", "mathematical_philosophy", "foundations" },
}
