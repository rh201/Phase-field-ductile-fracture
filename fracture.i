[Mesh]
  [generated_mesh]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 20
    ny = 100
    xmin = 0.0
    xmax = 2.0
    ymin = 0.0
    ymax = 10.0
  []
  [cnode]
    type = ExtraNodesetGenerator
    coord = '0.0 0.0 0.0'
    new_boundary = corner_point1
    input = generated_mesh
  []
[]

[Variables]
  [d]
  []
[]

[AuxVariables]
  [bounds_dummy]
  []
  [hist]
    order = CONSTANT
    family = MONOMIAL
  []
  [uncracked_plastic_energy] # plastic energy
    order = CONSTANT
    family = MONOMIAL
  []
[]

[Bounds]
  [irreversibility]
    type = VariableOldValueBoundsAux
    variable = bounds_dummy
    bounded_variable = d
    bound_type = lower
  []
  [upper]
    type = ConstantBoundsAux
    variable = bounds_dummy
    bounded_variable = d
    bound_type = upper
    bound_value = 1
  []
[]

[Kernels]
  [diff]
    type = ADPFFDiffusion
    variable = d
    fracture_toughness = Gc
    regularization_length = l
    normalization_constant = 2
  []
  [source]
    type = ADPFFSource
    variable = d
    free_energy = psi
  []
[]

[Materials]
  [fracture_properties]
    type = ADGenericConstantMaterial
    prop_names = 'Gc l'
    prop_values = '${Gc} ${l}'
  []
  [psi]
    type = ADDerivativeParsedMaterial
    f_name = psi
    function = 'd*d*Gc/2/l+(1-d)*(1-d)*(hist+uncracked_plastic_energy)'
    args = 'd hist uncracked_plastic_energy'
    material_property_names = 'Gc l '
    derivative_order = 1
    outputs = exodus
  []
[]

[Executioner]
  type = Transient

  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -snes_type'
  petsc_options_value = 'lu       superlu_dist                  vinewtonrsls'
  automatic_scaling = true

  nl_rel_tol = 1e-06
  nl_abs_tol = 1e-08
[]

[Outputs]
  exodus = true
  print_linear_residuals = false
[]
