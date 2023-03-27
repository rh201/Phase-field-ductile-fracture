#
# length: 1 mm
# time  : 1 s
# stress: 1 MPa

E = 68.8e3        # MPa
mu = 0.33         # --
Gc = 69           # 1e3 N/m
ft = 320          # MPa
H = 650           # MPa
l = 0.1          # 10e-3m

[GlobalParams]
  displacements = 'disp_x disp_y'
  volumetric_locking_correction = true
[]

[MultiApps]
  [fracture]
    type = TransientMultiApp
    input_files = fracture.i
    cli_args = 'Gc=${Gc};l=${l}'  # for wu
    execute_on = 'TIMESTEP_END'
  []
[]

[Transfers]
  [from_d]
    type = MultiAppMeshFunctionTransfer
    multi_app = fracture
    direction = from_multiapp
    variable = d
    source_variable = d
  []
  [to_psie_active]
    type = MultiAppMeshFunctionTransfer
    multi_app = fracture
    direction = to_multiapp
    variable = 'hist uncracked_plastic_energy'
    source_variable = 'hist uncracked_plastic_energy'
  []
[]

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
  [disp_x]
  []
  [disp_y]
  []
[]

[AuxVariables]
  [hist] # elastic energy
    order = CONSTANT
    family = MONOMIAL
  []
  [uncracked_plastic_energy] # plastic energy
    order = CONSTANT
    family = MONOMIAL
  []
  [fy]
  []
  [d]
  []
[]

[AuxKernels]
  [hist]
    type = ADMaterialRealAux
    variable = hist
    property = hist
  []
  [uncracked_plastic_energy]
    type = ADMaterialRealAux
    variable = uncracked_plastic_energy
    property = uncracked_plastic_energy
  []
[]

[Kernels]
  [solid_x]
    type = ADStressDivergenceTensors
    variable = disp_x
    component = 0
  []
  [solid_y]
    type = ADStressDivergenceTensors
    variable = disp_y
    component = 1
    save_in = fy
  []
[]

[BCs]
  [ydisp]
    type = FunctionDirichletBC
    variable = disp_y
    boundary = top
    function = 't'
  []
  [xfix]
    type = DirichletBC
    variable = disp_y
    boundary = bottom
    value = 0
  []
  [yfix]
    type = DirichletBC
    variable = disp_x
    boundary = corner_point1
    value = 0
  []
[]

[Materials]
  [bulk]
    type = ADGenericConstantMaterial
    prop_names = ' Gc  gc_prop  l     ft  H E visco'                   # for power
    prop_values = ' ${Gc} ${Gc} ${l}  ${ft}  ${H} ${E} 0.0001'
  []
  [strain]
    type = ADComputeIncrementalSmallStrain
    base_name = uncracked
  []
  [elasticity_tensor]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = ${E}
    poissons_ratio = ${mu}
    base_name = uncracked
  []
  [./isotropic_plasticity]
    type = ADIsotropicPlasticityStressUpdate
    yield_stress = ${ft}
    hardening_constant = ${H}
    # relative_tolerance = 1e-20
    # absolute_tolerance = 1e-8
    # max_inelastic_increment = 0.000001
    base_name = uncracked
  [../]
  [./radial_return_stress]
    type = ADComputeMultipleInelasticStress
    # tangent_operator = elastic
    inelastic_models = 'isotropic_plasticity'
    base_name = uncracked
  [../]
  [./compute_plastic_energy]
    type = ADComputePlasticEnergy
    c = d
    yield_stress = ${ft}
    hardening_modulus = ${H}
    base_name = uncracked
    # outputs = exodus
  []
  [./degradation]
    type = ADDerivativeParsedMaterial
    f_name = 'degradation'
    args = 'd'
    function = '(1.0-d)^2*(1.0 - eta) + eta'
    material_property_names = 'Gc E ft  l '
    constant_names       = 'c0 eta'
    constant_expressions = '3.1415926 1e-8'
    derivative_order = 2
  [../]
  [./cracked_stress]
    type = ADComputePFCrackedStress
    c = d
    kdamage = 1e-8
    D_name = 'degradation'
    use_current_history_variable = true
    uncracked_base_name = uncracked
    finite_strain_model = true
    # outputs = exodus
  [../]
[]

[Postprocessors]
  [fy]
    type = NodalSum
    variable = fy
    boundary = top
  []
  [./d_average]
    type = ElementAverageValue
    variable = d
  [../]
  [./run_time]
    type = PerfGraphData
    section_name = "Root"
    data_type = total
  [../]
  [./dt]
    type = TimestepSize
  [../]
[]

[Executioner]
  type = Transient

  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu       superlu_dist                 '
  automatic_scaling = true


  dt = 0.005
  end_time = 10
  nl_rel_tol = 1e-06
  nl_abs_tol = 1e-08

  picard_max_its = 100
  picard_abs_tol = 1e-50
  picard_rel_tol = 1e-03
  accept_on_max_picard_iteration = true
[]

[Outputs]
  exodus = true
  csv = true
[]
