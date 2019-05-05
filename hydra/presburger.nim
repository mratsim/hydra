type
  PFormulaKind = enum
    # Presburger Formula kind
    pfkAdd
    pfkSub
    pfkEQ        # equal
    # pfkLE      # lower or equal
    # pfkLT      # lower
    pfkGE        # greater or equal
    pfkGT        # greater
    # pfkNE      # not equal
    pfkMul       # Multiply (lhs must be const)
    # pfkLexLE
    # pfkLexLR
    pfkLexGE     # Lexicographically greater or equal (i, j) >>= (k, l)
    pfkLexGR
    pfkMod       # Modulo
    pfkTrue      # True
    pfkFalse     # False
    pfkAnd       # And
    pfkOr        # Or
    pfkNot       # Negation
    pfkImplies   # Implies
    pfkExists    # Exists
    pfkNotExists # Not exists

  BasicMapFlags = enum
    Final
    Empty
    NoImplicit
    NoRedundant
    Rational
    Sorted
    NormalizedDivs
    AllEqualities
    ReducedCoefficients

  BasicMap = ref object
    # Presburger Map
    flags: set[BasicMapFlags]
    n_eq: int   # Number of equalities
    n_ineq: int # Number of inequalities

    eq: ref seq[int]
    ineq: ref seq[int]

    n_div: int
    divs: ref seq[int]

    sample: ref seq[int]

  MapFlags = enum
    Disjoint
    Normalized

  Map = ref object
    flags: MapFlags
    cached_simple_hull: array[2, BasicMap]
    n: int
    size: int
    p: BasicMap

  BasicPSet = distinct BasicMap
  PSet = distinct Map