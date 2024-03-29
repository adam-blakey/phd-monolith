module matrix_rhs_transport_mm
    use bcs_transport
    use problem_options
    use problem_options_transport
    use problem_options_geometry
    use solution_storage_velocity
    use previous_timestep
    use basis_fns_storage_type
    use aptofem_fe_matrix_assembly
    use base_solution_type

    implicit none

    contains

    subroutine stiffness_matrix_load_vector_transport_mm(element_matrix, element_rhs, mesh_data, soln_data, facet_data, &
            fe_basis_info)
        include "assemble_matrix_rhs_element.h"

        !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        !! CONTAINED IN HEADER FILE !!
        !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        ! use param
        ! use fe_mesh
        ! use fe_solution
        ! use basis_fns_storage_type
        ! use matrix_assembly_data_type

        ! implicit none

        ! type(basis_storage), intent(in) :: fe_basis_info !< FE basis functions
        ! type(matrix_assembly_data_facet), intent(in) :: facet_data !< Facet data
        ! real(db), dimension(facet_data%dim_soln_coeff,facet_data%dim_soln_coeff, &
        ! facet_data%no_dofs_per_var_max,facet_data%no_dofs_per_var_max), &
        ! intent(out) :: element_matrix !< Element stiffness matrices
        ! !< computed for each variable in the system
        ! real(db), dimension(facet_data%dim_soln_coeff,facet_data%no_dofs_per_var_max), &
        ! intent(out) :: element_rhs
        ! !< Element rhs vector for each PDE equation in the system
        ! type(mesh), intent(in) :: mesh_data !< FE mesh
        ! type(solution), intent(in) :: soln_data !< FE solution

        !!!!!!!!!!!!!!!
        !! VARIABLES !!
        !!!!!!!!!!!!!!!
        integer  :: i, j
        integer  :: q
        real(db) :: diffusion_terms, convection_terms, reaction_terms, time_terms, forcing_terms, prev_time_terms

        real(db), dimension(facet_data%no_pdes)      :: f
        real(db), dimension(facet_data%dim_soln_coeff, facet_data%no_quad_points, &
            maxval(facet_data%no_dofs_per_variable)) :: phi
        real(db), dimension(facet_data%dim_soln_coeff, facet_data%no_quad_points, facet_data%problem_dim, &
            maxval(facet_data%no_dofs_per_variable)) :: phi_1

        real(db) :: time_step, current_time

        real(db), dimension(facet_data%problem_dim)                         :: u_darcy_velocity
        real(db), dimension(facet_data%problem_dim, facet_data%problem_dim) :: u_darcy_velocity_1

        ! Previous solution variables.
        real(db), dimension(facet_data%no_pdes, facet_data%no_quad_points) :: prev_ch
        real(db), dimension(facet_data%problem_dim, facet_data%no_quad_points) :: prev_global_points_ele
        real(db), dimension(facet_data%no_quad_points) :: prev_jacobian, prev_quad_weights_ele
        real(db), dimension(facet_data%dim_soln_coeff, facet_data%no_quad_points, maxval(facet_data%no_dofs_per_variable)) :: &
            prev_phi
        integer, dimension(facet_data%dim_soln_coeff, maxval(facet_data%no_dofs_per_variable)) :: prev_global_dof_numbers
        integer, dimension(facet_data%dim_soln_coeff) :: prev_no_dofs_per_variable
        integer :: prev_no_quad_points

        character(len=aptofem_length_key_def) :: control_parameter

        integer             :: prev_dim_soln_coeff, prev_no_pdes, prev_no_elements, prev_no_nodes, prev_no_faces, prev_problem_dim,&
            prev_npinc, prev_no_quad_points_volume_max, prev_no_quad_points_face_max
        type(basis_storage) :: prev_fe_basis_info

        ! Moving mesh variables.
        real(db), dimension(facet_data%problem_dim) :: mesh_velocity
        real(db), dimension(facet_data%problem_dim, facet_data%no_quad_points) :: mesh_uh
        real(db), dimension(facet_data%problem_dim, facet_data%no_quad_points) :: mesh_global_points_ele
        real(db), dimension(facet_data%no_quad_points) :: mesh_jacobian, mesh_quad_weights_ele
        real(db), dimension(facet_data%problem_dim, facet_data%no_quad_points, &
            facet_data%problem_dim*maxval(facet_data%no_dofs_per_variable)) :: mesh_phi
        integer, dimension(facet_data%problem_dim, facet_data%problem_dim*maxval(facet_data%no_dofs_per_variable)) :: &
            mesh_global_dof_numbers
        integer, dimension(facet_data%problem_dim) :: mesh_no_dofs_per_variable
        integer :: mesh_no_quad_points

        integer             :: mesh_dim_soln_coeff, mesh_no_pdes, mesh_no_elements, mesh_no_nodes, mesh_no_faces, mesh_problem_dim,&
            mesh_npinc, mesh_no_quad_points_volume_max, mesh_no_quad_points_face_max
        type(basis_storage) :: mesh_fe_basis_info

        ! Extra variables on previous mesh.
        real(db), dimension(facet_data%problem_dim, facet_data%no_quad_points) :: &
        prev_gauss_points_local, prev_gauss_points_global, mesh_gauss_points_local, mesh_gauss_points_global
        real(db), dimension(facet_data%problem_dim, facet_data%problem_dim, facet_data%no_quad_points) :: &
        prev_jacobi_mat, prev_inv_jacobi_mat, mesh_jacobi_mat, mesh_inv_jacobi_mat
        integer :: prev_dim_soln_coeff_start, prev_dim_soln_coeff_end, prev_dim_soln_coeff_fe_space, mesh_dim_soln_coeff_start, &
        mesh_dim_soln_coeff_end, mesh_dim_soln_coeff_fe_space

        ! Setup basis storage.
        control_parameter = 'uh_ele'
        ! I think the only reason we need prev_fe_basis_info is for the basis_element property, which we're not allowed to access
        !  from fe_basis_info due to the intent().
        call initialize_fe_basis_storage(prev_fe_basis_info, control_parameter, prev_solution_transport_data, &
            facet_data%problem_dim, facet_data%no_quad_points_volume_max, facet_data%no_quad_points_face_max)
        call initialize_fe_basis_storage(mesh_fe_basis_info, control_parameter, solution_moving_mesh, &
            facet_data%problem_dim, facet_data%no_quad_points_volume_max, facet_data%no_quad_points_face_max)

        ! Get element DoFs for moving mesh solution.
        mesh_dim_soln_coeff = get_dim_soln_coeff(solution_moving_mesh)
        call get_element_dof_numbers(prev_mesh_data, solution_moving_mesh, mesh_global_dof_numbers, mesh_no_dofs_per_variable, &
            facet_data%element_number, mesh_dim_soln_coeff)

        ! Get element info (definitely required for prev_uh, unsure about mesh_uh).
        prev_no_quad_points = facet_data%no_quad_points
        mesh_no_quad_points = facet_data%no_quad_points
        call get_element_transform_quad_pts(prev_mesh_data, facet_data%element_number, facet_data%problem_dim, &
        prev_gauss_points_local, prev_global_points_ele, prev_quad_weights_ele, prev_no_quad_points, prev_jacobi_mat, &
        prev_jacobian)
        call get_element_transform_quad_pts(prev_mesh_data, facet_data%element_number, facet_data%problem_dim, &
        mesh_gauss_points_local, mesh_global_points_ele, mesh_quad_weights_ele, mesh_no_quad_points, mesh_jacobi_mat, &
        mesh_jacobian)

        do i = 1, prev_solution_transport_data%no_fem_spaces
        prev_dim_soln_coeff_start    = prev_solution_transport_data%fem_spaces(i)%fem%dim_soln_coeff_start_end(1)
        prev_dim_soln_coeff_end      = prev_solution_transport_data%fem_spaces(i)%fem%dim_soln_coeff_start_end(2)
        prev_dim_soln_coeff_fe_space = prev_solution_transport_data%fem_spaces(i)%fem%dim_soln_coeff_fe_space

        call prev_solution_transport_data%fem_spaces(i)%fem%basis_fns_stored_quad_pts(prev_mesh_data, facet_data%element_number, &
            facet_data%problem_dim, facet_data%no_quad_points, prev_dim_soln_coeff_fe_space, &
            prev_gauss_points_local(:, 1:facet_data%no_quad_points), prev_gauss_points_global(:, 1:facet_data%no_quad_points), &
            prev_no_dofs_per_variable, prev_fe_basis_info%basis_element, prev_jacobi_mat(:, :, 1:facet_data%no_quad_points), &
            prev_jacobian(1:facet_data%no_quad_points))
        end do

        do i = 1, solution_moving_mesh%no_fem_spaces
        mesh_dim_soln_coeff_start    = solution_moving_mesh%fem_spaces(i)%fem%dim_soln_coeff_start_end(1)
        mesh_dim_soln_coeff_end      = solution_moving_mesh%fem_spaces(i)%fem%dim_soln_coeff_start_end(2)
        mesh_dim_soln_coeff_fe_space = solution_moving_mesh%fem_spaces(i)%fem%dim_soln_coeff_fe_space

        call solution_moving_mesh%fem_spaces(i)%fem%basis_fns_stored_quad_pts(prev_mesh_data, facet_data%element_number, &
            facet_data%problem_dim, facet_data%no_quad_points, mesh_dim_soln_coeff_fe_space, &
            mesh_gauss_points_local(:, 1:facet_data%no_quad_points), mesh_global_points_ele(:, 1:facet_data%no_quad_points), &
            mesh_no_dofs_per_variable, mesh_fe_basis_info%basis_element, mesh_jacobi_mat(:, :, 1:facet_data%no_quad_points), &
            mesh_jacobian(1:facet_data%no_quad_points))
        end do

        call compute_uh_with_basis_fns_pts(prev_ch(:, 1:facet_data%no_quad_points), facet_data%no_pdes, facet_data%no_quad_points, &
            facet_data%dim_soln_coeff, facet_data%no_dofs_per_variable, facet_data%global_dof_numbers, fe_basis_info%basis_element,&
            prev_solution_transport_data)
        call compute_uh_with_basis_fns_pts(mesh_uh(:, 1:facet_data%no_quad_points), facet_data%problem_dim, &
            facet_data%no_quad_points, mesh_dim_soln_coeff, mesh_no_dofs_per_variable, mesh_global_dof_numbers, &
            mesh_fe_basis_info%basis_element, solution_moving_mesh)

        associate(&
            dim_soln_coeff       => facet_data%dim_soln_coeff, &
            no_pdes              => facet_data%no_pdes, &
            problem_dim          => facet_data%problem_dim, &
            no_quad_points       => facet_data%no_quad_points, &
            global_points        => facet_data%global_points, &
            integral_weighting   => facet_data%integral_weighting, &
            element_no           => facet_data%element_number, &
            element_region_id    => facet_data%element_region_id, &
            global_dof_numbers   => facet_data%global_dof_numbers, &
            no_dofs_per_variable => facet_data%no_dofs_per_variable, &
            scheme_user_data     => facet_data%scheme_user_data &
        )
            select type (scheme_user_data)
            type is (default_user_data)
                time_step    = scheme_user_data%time_step
                current_time = scheme_user_data%current_time
            end select

            element_matrix = 0.0_db
            element_rhs    = 0.0_db

            ! Calculate basis functions on current mesh.
            do i = 1, dim_soln_coeff
                phi  (i, 1:no_quad_points,                1:no_dofs_per_variable(i)) &
                    = fe_basis_info%basis_element%basis_fns(i) &
                    %fem_basis_fns(1:no_quad_points, 1:no_dofs_per_variable(i), 1)
                phi_1(i, 1:no_quad_points, 1:problem_dim, 1:no_dofs_per_variable(i)) &
                    = fe_basis_info%basis_element%deriv_basis_fns(i) &
                    %grad_data(1:no_quad_points, 1:problem_dim, 1:no_dofs_per_variable(i), 1)
            end do

            ! Calculate basis functions on previous mesh.
            do i = 1, dim_soln_coeff
                prev_phi(i, 1:no_quad_points, 1:no_dofs_per_variable(i)) = &
                    fe_basis_info%basis_element%basis_fns(i)%fem_basis_fns(1:no_quad_points, 1:no_dofs_per_variable(i), 1)
            end do

            do q = 1, no_quad_points
                mesh_velocity = mesh_uh(1:problem_dim, q)

                call calculate_convective_velocity_0_1(u_darcy_velocity, u_darcy_velocity_1, global_points(:, q), problem_dim, &
                    element_no, mesh_data)

                call forcing_function_transport(f, global_points(:, q), problem_dim, no_pdes, current_time)

                do i = 1, no_dofs_per_variable(1)
                    prev_time_terms = prev_phi(1, q, i)*prev_ch(1, q)/time_step
                    forcing_terms   = phi(1, q, i)*f(1)

                    element_rhs(1, i) = element_rhs(1, i) + &
                        integral_weighting(q)* &
                            forcing_terms*calculate_transport_forcing_coefficient(global_points(:, q), problem_dim, &
                                element_region_id) + &
                        prev_jacobian(q)*prev_quad_weights_ele(q)* &
                            prev_time_terms*calculate_transport_time_coefficient(prev_gauss_points_global(:, q), problem_dim, &
                                element_region_id)

                    do j = 1, no_dofs_per_variable(1)
                        time_terms       = phi(1, q, i)*phi(1, q, j)/time_step
                        diffusion_terms  = dot_product(phi_1(1, q, :, i), phi_1(1, q, :, j))
                        convection_terms = -dot_product(u_darcy_velocity-mesh_velocity, phi_1(1, q, :, i))*phi(1, q, j)
                        reaction_terms   = phi(1, q, j)*phi(1, q, i)

                        element_matrix(1, 1, i, j) = element_matrix(1, 1, i, j) + integral_weighting(q)*( &
                            time_terms      *calculate_transport_time_coefficient(global_points(:, q), problem_dim, &
                                element_region_id) + &
                            diffusion_terms *calculate_transport_diffusion_coefficient(global_points(:, q), problem_dim, &
                                element_region_id) + &
                            convection_terms*calculate_transport_convection_coefficient(global_points(:, q), problem_dim, &
                                element_region_id) + &
                            reaction_terms  *calculate_transport_reaction_coefficient(global_points(:, q), problem_dim, &
                                element_region_id) &
                        )

                    end do
                end do
            end do

        end associate

        call delete_fe_basis_storage(prev_fe_basis_info)
        call delete_fe_basis_storage(mesh_fe_basis_info)

    end subroutine

    subroutine stiffness_matrix_load_vector_face_transport_mm(face_matrix_pp, face_matrix_pm, face_matrix_mp, face_matrix_mm,  &
        face_rhs, mesh_data, soln_data, facet_data, fe_basis_info)

        use problem_options_transport
        use bcs_transport

        include 'assemble_matrix_rhs_face.h'

        !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        !! CONTAINED IN HEADER FILE !!
        !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        ! use param
        ! use fe_mesh
        ! use fe_solution
        ! use basis_fns_storage_type
        ! use matrix_assembly_data_type

        ! implicit none

        ! type(basis_storage), intent(in) :: fe_basis_info !< FE basis functions
        ! type(matrix_assembly_data_facet), intent(in) :: facet_data !< Facet data
        ! real(db), dimension(facet_data%dim_soln_coeff,facet_data%dim_soln_coeff, &
        ! facet_data%no_dofs_per_var_max,facet_data%no_dofs_per_var_max), &
        ! intent(out) :: face_matrix_pp !< Face stiffness matrix
        ! !< involving the plus-plus contributions with respect to the
        ! !< first element neighboring the face
        ! real(db), dimension(facet_data%dim_soln_coeff,facet_data%dim_soln_coeff, &
        ! facet_data%no_dofs_per_var_max,facet_data%no_dofs_per_var_max), &
        ! intent(out) :: face_matrix_pm !< Face stiffness matrix
        ! !< involving the plus-minus contributions with respect to the
        ! !< first element neighboring the face
        ! real(db), dimension(facet_data%dim_soln_coeff,facet_data%dim_soln_coeff, &
        ! facet_data%no_dofs_per_var_max,facet_data%no_dofs_per_var_max), &
        ! intent(out) :: face_matrix_mp !< Face stiffness matrix
        ! !< involving the minus-plus contributions with respect to the
        ! !< first element neighboring the face
        ! real(db), dimension(facet_data%dim_soln_coeff,facet_data%dim_soln_coeff, &
        ! facet_data%no_dofs_per_var_max,facet_data%no_dofs_per_var_max), &
        ! intent(out) :: face_matrix_mm !< Face stiffness matrix
        ! !< involving the minus-minus contributions with respect to the
        ! !< first element neighboring the face
        ! real(db), dimension(facet_data%dim_soln_coeff,facet_data%no_dofs_per_var_max), &
        ! intent(out) :: face_rhs
        ! !< Face rhs vector for each PDE equation in the system
        ! type(mesh), intent(in) :: mesh_data !< FE mesh
        ! type(solution), intent(in) :: soln_data !< FE solution

        integer                                        :: qk, i, j
        real(db)                                       :: full_dispenal, full_dispenal_old
        real(db)                                       :: diffusion_terms, convection_terms
        real(db), dimension(facet_data%no_pdes)        :: f, c, cn
        real(db), dimension(facet_data%dim_soln_coeff) :: dispenal_new
        real(db), dimension(facet_data%dim_soln_coeff, facet_data%no_quad_points, facet_data%problem_dim, &
            maxval(facet_data%no_dofs_per_variable1))  :: grad_phi_p
        real(db), dimension(facet_data%dim_soln_coeff, facet_data%no_quad_points, facet_data%problem_dim, &
            maxval(facet_data%no_dofs_per_variable2))  :: grad_phi_m
        real(db)                                       :: current_time
        real(db)                                       :: a_dot_n_p, a_dot_n_m
        real(db)                                       :: deriv_flux_plus, deriv_flux_minus, alpha
        integer                                        :: bdry_face
        integer                                        :: element_no

        real(db), dimension(facet_data%dim_soln_coeff, facet_data%no_quad_points, maxval(facet_data%no_dofs_per_variable1)) :: phi_p
        real(db), dimension(facet_data%dim_soln_coeff, facet_data%no_quad_points, maxval(facet_data%no_dofs_per_variable1)) :: phi_m

        real(db), dimension(facet_data%problem_dim+1) :: u_darcy_p
        real(db), dimension(facet_data%problem_dim+1) :: u_darcy_m
        real(db), dimension(facet_data%problem_dim)   :: u_darcy_velocity_p
        real(db), dimension(facet_data%problem_dim)   :: u_darcy_velocity_m

        ! Moving mesh variables.
        real(db), dimension(facet_data%problem_dim) :: mesh_velocity
        real(db), dimension(facet_data%problem_dim, facet_data%no_quad_points) :: mesh_uh
        real(db), dimension(facet_data%problem_dim, facet_data%no_quad_points_face_max) :: mesh_global_points_face, &
            mesh_face_normals
        real(db), dimension(facet_data%no_quad_points_face_max) :: mesh_face_jacobian, mesh_quad_weights_face
        real(db), dimension(facet_data%problem_dim, facet_data%no_quad_points_face_max, &
            facet_data%problem_dim*maxval(facet_data%no_dofs_per_variable)) :: mesh_phi
        integer, dimension(facet_data%problem_dim, facet_data%problem_dim*maxval(facet_data%no_dofs_per_variable1)) :: &
            mesh_global_dof_numbers1, mesh_global_dof_numbers2
        integer, dimension(facet_data%problem_dim) :: mesh_no_dofs_per_variable1, mesh_no_dofs_per_variable2
        integer :: mesh_no_quad_points
        integer, dimension(2) :: mesh_neighbors, mesh_loc_face_no

        ! Additional variables on previous mesh.
        integer :: element_no1, element_no2, mesh_dim_soln_coeff_start, mesh_dim_soln_coeff_end, mesh_dim_soln_coeff_fe_space
        real(db), dimension(facet_data%problem_dim, facet_data%no_quad_points) :: mesh_local_points1, mesh_local_points2, &
        mesh_global_points
        real(db), dimension(facet_data%problem_dim, facet_data%problem_dim, facet_data%no_quad_points) :: mesh_jacobi_mat1, &
        mesh_inv_jacobi_mat1, mesh_jacobi_mat2
        real(db), dimension(facet_data%no_quad_points) :: mesh_jacobian1, mesh_jacobian2

        character(len=aptofem_length_key_def) :: control_parameter

        integer             :: mesh_dim_soln_coeff, mesh_no_pdes, mesh_no_elements, mesh_no_nodes, mesh_no_faces, mesh_problem_dim,&
        mesh_npinc, mesh_no_quad_points_volume_max, mesh_no_quad_points_face_max, mesh_bdry_face
        type(basis_storage) :: mesh_fe_basis_info

        ! Setup basis storage (purely for quadrature points).
        control_parameter = 'uh_face'
        call initialize_fe_basis_storage(mesh_fe_basis_info, control_parameter, solution_moving_mesh, &
        facet_data%problem_dim, facet_data%no_quad_points_volume_max, facet_data%no_quad_points_face_max)

        ! Assuming continuity, we will mostly just work on face 1; in fact it probably could work with just face 1; I 
        !  suspect problems may arise in compute_uh_with_basis_fns_pts if we don't do anything to face 2.
        element_no1 = facet_data%neighbours(1)
        element_no2 = facet_data%neighbours(2)

        ! Get the local face numbers.
        mesh_loc_face_no = mesh_data%mesh_faces(facet_data%face_number)%loc_face_no

        ! Get element DoFs for moving mesh solution.
        mesh_dim_soln_coeff = get_dim_soln_coeff(solution_moving_mesh)
        call get_element_dof_numbers(prev_mesh_data, solution_moving_mesh, mesh_global_dof_numbers1, mesh_no_dofs_per_variable1, &
        element_no1, mesh_dim_soln_coeff)

        ! Get face integration info.
        mesh_no_quad_points = facet_data%no_quad_points
        call get_face_transform_quad_pts(prev_mesh_data, element_no1, mesh_loc_face_no(1), facet_data%problem_dim, &
        mesh_local_points1(:,1:facet_data%no_quad_points), mesh_global_points(:, 1:facet_data%no_quad_points), &
        mesh_quad_weights_face(1:facet_data%no_quad_points), mesh_no_quad_points, mesh_face_jacobian(1:facet_data%no_quad_points), &
        mesh_face_normals(:, 1:facet_data%no_quad_points), mesh_jacobi_mat1(:, :, 1:facet_data%no_quad_points), &
        mesh_jacobian1(1:facet_data%no_quad_points), mesh_inv_jacobi_mat1(:, :, 1:facet_data%no_quad_points))

        do i = 1, solution_moving_mesh%no_fem_spaces
        mesh_dim_soln_coeff_start    = solution_moving_mesh%fem_spaces(i)%fem%dim_soln_coeff_start_end(1)
        mesh_dim_soln_coeff_end      = solution_moving_mesh%fem_spaces(i)%fem%dim_soln_coeff_start_end(2)
        mesh_dim_soln_coeff_fe_space = solution_moving_mesh%fem_spaces(i)%fem%dim_soln_coeff_fe_space

        call solution_moving_mesh%fem_spaces(i)%fem%uh_basis_fns_pts(prev_mesh_data, solution_moving_mesh, &
            element_no1, facet_data%problem_dim, facet_data%no_quad_points, mesh_dim_soln_coeff_fe_space, &
            mesh_local_points1(:, 1:facet_data%no_quad_points), mesh_global_points(:, 1:facet_data%no_quad_points), &
            mesh_no_dofs_per_variable1, mesh_fe_basis_info%basis_face1, mesh_jacobi_mat1(:, :, 1:facet_data%no_quad_points), &
            mesh_jacobian1(1:facet_data%no_quad_points))
        if (element_no2 > 0) then
            call solution_moving_mesh%fem_spaces(i)%fem%uh_basis_fns_pts(prev_mesh_data, solution_moving_mesh, &
            element_no2, facet_data%problem_dim, facet_data%no_quad_points, mesh_dim_soln_coeff_fe_space, &
            mesh_local_points2(:, 1:facet_data%no_quad_points), mesh_global_points(:, 1:facet_data%no_quad_points), &
            mesh_no_dofs_per_variable2, mesh_fe_basis_info%basis_face2, mesh_jacobi_mat2(:, :, 1:facet_data%no_quad_points), &
            mesh_jacobian2(1:facet_data%no_quad_points))
        end if
        end do

        call compute_uh_with_basis_fns_pts(mesh_uh(:, 1:facet_data%no_quad_points), facet_data%problem_dim, &
            facet_data%no_quad_points, mesh_dim_soln_coeff, mesh_no_dofs_per_variable1, mesh_global_dof_numbers1, &
            mesh_fe_basis_info%basis_face1, solution_moving_mesh)

        associate( &
            dim_soln_coeff            => facet_data%dim_soln_coeff, &
            no_pdes                   => facet_data%no_pdes, &
            problem_dim               => facet_data%problem_dim, &
            no_quad_points            => facet_data%no_quad_points, &
            global_points_face        => facet_data%global_points, &
            integral_weighting        => facet_data%integral_weighting, &
            face_number               => facet_data%face_number, &
            interior_face_boundary_no => facet_data%interior_face_boundary_no, &
            face_element_region_ids   => facet_data%face_element_region_ids, &
            bdry_face_old             => facet_data%bdry_no, &
            no_dofs_per_variable1     => facet_data%no_dofs_per_variable1, &
            no_dofs_per_variable2     => facet_data%no_dofs_per_variable2, &
            face_normals              => facet_data%face_normals, &
            dispenal                  => facet_data%dispenal, &
            scheme_user_data          => facet_data%scheme_user_data, &
            neighbour_elements        => facet_data%neighbours &
        )

            select type (scheme_user_data)
            type is (default_user_data)
                current_time = scheme_user_data%current_time
            end select

            call convert_transport_boundary_no(bdry_face_old, bdry_face)

            element_no = get_interior_face_boundary_no(face_number, mesh_data)

            face_matrix_pp = 0.0_db
            face_matrix_pm = 0.0_db
            face_matrix_mp = 0.0_db
            face_matrix_mm = 0.0_db
            face_rhs       = 0.0_db

            do i = 1, dim_soln_coeff
                grad_phi_p(i, 1:no_quad_points, 1:problem_dim, 1:no_dofs_per_variable1(i)) = fe_basis_info%basis_face1 &
                    %deriv_basis_fns(i)%grad_data(1:no_quad_points, 1:problem_dim, 1:no_dofs_per_variable1(i), 1)
                grad_phi_m(i, 1:no_quad_points, 1:problem_dim, 1:no_dofs_per_variable2(i)) = fe_basis_info%basis_face2 &
                    %deriv_basis_fns(i)%grad_data(1:no_quad_points, 1:problem_dim, 1:no_dofs_per_variable2(i), 1)

                phi_p(i, 1:no_quad_points, 1:no_dofs_per_variable1(i)) = fe_basis_info%basis_face1%basis_fns(i) &
                    %fem_basis_fns(1:no_quad_points, 1:no_dofs_per_variable1(i), 1)
                phi_m(i, 1:no_quad_points, 1:no_dofs_per_variable2(i)) = fe_basis_info%basis_face2%basis_fns(i) &
                    %fem_basis_fns(1:no_quad_points, 1:no_dofs_per_variable2(i), 1)
            end do

            full_dispenal = interior_penalty_parameter*dispenal(1)

            if (bdry_face > 0) then
                if (100 <= bdry_face .and. bdry_face <= 199) then
                    do qk = 1, no_quad_points
                        ! The solution is continuous, so we only need to do this on one side of the face.
                        mesh_velocity = mesh_uh(1:problem_dim, qk)

                        call calculate_convective_velocity(u_darcy_velocity_p, global_points_face(:, qk), problem_dim, &
                            neighbour_elements(1), mesh_data)

                        a_dot_n_p        = dot_product(u_darcy_velocity_p - mesh_velocity, face_normals(:, qk))
                        alpha            = abs(a_dot_n_p)
                        deriv_flux_plus  = 0.5_db*(a_dot_n_p + alpha)
                        deriv_flux_minus = 0.5_db*(a_dot_n_p - alpha)

                        call anal_soln_transport(c, global_points_face(:, qk), problem_dim, no_pdes, bdry_face, current_time)

                        do i = 1, no_dofs_per_variable1(1)
                            diffusion_terms = &
                                -dot_product(grad_phi_p(1, qk, :, i), face_normals(:, qk))*c(1) + full_dispenal*phi_p(1, qk, i)*c(1)

                            convection_terms = &
                                -deriv_flux_minus*c(1)*phi_p(1, qk, i)

                            face_rhs(1, i) = face_rhs(1, i) + integral_weighting(qk)* &
                            ( &
                                diffusion_terms *calculate_transport_diffusion_coefficient(global_points_face(:, qk), &
                                    problem_dim, face_element_region_ids(1)) + &
                                convection_terms*calculate_transport_convection_coefficient(global_points_face(:, qk), &
                                    problem_dim, face_element_region_ids(1)) &
                            )

                            do j = 1, no_dofs_per_variable1(1)
                                diffusion_terms = &
                                    -dot_product(grad_phi_p(1, qk, :, i), face_normals(:, qk))*phi_p(1, qk, j) &
                                    -dot_product(grad_phi_p(1, qk, :, j), face_normals(:, qk))*phi_p(1, qk, i) &
                                    +full_dispenal*phi_p(1, qk, j)*phi_p(1, qk, i)

                                convection_terms = &
                                    deriv_flux_plus*phi_p(1, qk, j)*phi_p(1, qk, i)

                                face_matrix_pp(1, 1, i, j) = face_matrix_pp(1, 1, i, j) + integral_weighting(qk) * &
                                ( &
                                    diffusion_terms *calculate_transport_diffusion_coefficient(global_points_face(:, qk), &
                                        problem_dim, face_element_region_ids(1)) + &
                                    convection_terms*calculate_transport_convection_coefficient(global_points_face(:, qk), &
                                        problem_dim, face_element_region_ids(1)) &
                                )
                            end do
                        end do
                    end do
                else if (200 <= bdry_face .and. bdry_face <= 299) then
                    do qk = 1, no_quad_points
                        ! The solution is continuous, so we only need to do this on one side of the face.
                        mesh_velocity = mesh_uh(1:problem_dim, qk)

                        call calculate_convective_velocity(u_darcy_velocity_p, global_points_face(:, qk), problem_dim, &
                            neighbour_elements(1), mesh_data)

                        a_dot_n_p        = dot_product(u_darcy_velocity_p - mesh_velocity, face_normals(:, qk))
                        alpha            = abs(a_dot_n_p)
                        deriv_flux_plus  = 0.5_db*(a_dot_n_p + alpha)
                        deriv_flux_minus = 0.5_db*(a_dot_n_p - alpha)

                        call neumann_bc_transport(cn, global_points_face(:, qk), problem_dim, no_pdes, current_time, face_normals)

                        do i = 1, no_dofs_per_variable1(1)
                            diffusion_terms = cn(1)*phi_p(1, qk, i)

                            face_rhs(1, i) = face_rhs(1, i) + &
                                integral_weighting(qk)*diffusion_terms

                            do j = 1, no_dofs_per_variable1(1)
                                convection_terms = &
                                    deriv_flux_plus*phi_p(1, qk, j)*phi_p(1, qk, i)

                                face_matrix_pp(1, 1, i, j) = face_matrix_pp(1, 1, i, j) + integral_weighting(qk) * &
                                ( &
                                    convection_terms*calculate_transport_convection_coefficient(global_points_face(:, qk), &
                                        problem_dim, face_element_region_ids(1)) &
                                )
                            end do
                        end do
                    end do
                end if
            else
                do qk = 1, no_quad_points
                    ! The solution is continuous, so we only need to do this on one side of the face.
                    mesh_velocity = mesh_uh(1:problem_dim, qk)

                    call calculate_convective_velocity(u_darcy_velocity_p, global_points_face(:, qk), problem_dim, &
                        neighbour_elements(1), mesh_data)
                    call calculate_convective_velocity(u_darcy_velocity_m, global_points_face(:, qk), problem_dim, &
                        neighbour_elements(2), mesh_data)

                    a_dot_n_p        = dot_product(u_darcy_velocity_p - mesh_velocity, face_normals(:, qk))
                    a_dot_n_m        = dot_product(u_darcy_velocity_m - mesh_velocity, face_normals(:, qk))
                    alpha            = 0.5_db*abs(a_dot_n_p + a_dot_n_m)
                    deriv_flux_plus  = 0.5_db*(a_dot_n_p + alpha)
                    deriv_flux_minus = 0.5_db*(a_dot_n_m - alpha)

                    do i = 1, no_dofs_per_variable1(1)
                        do j = 1, no_dofs_per_variable1(1)
                            diffusion_terms = &
                                -0.5_db*dot_product(grad_phi_p(1, qk, :, i), face_normals(:, qk))*phi_p(1, qk, j) &
                                -0.5_db*dot_product(grad_phi_p(1, qk, :, j), face_normals(:, qk))*phi_p(1, qk, i) &
                                +full_dispenal*phi_p(1, qk, j)*phi_p(1, qk, i)

                            convection_terms = &
                                deriv_flux_plus*phi_p(1, qk, j)*phi_p(1, qk, i)

                            face_matrix_pp(1, 1, i, j) = face_matrix_pp(1, 1, i, j) + integral_weighting(qk)*( &
                                diffusion_terms *calculate_transport_diffusion_coefficient(global_points_face(:, qk), &
                                    problem_dim, face_element_region_ids(1)) + &
                                convection_terms*calculate_transport_convection_coefficient(global_points_face(:, qk), &
                                    problem_dim, face_element_region_ids(1)) &
                            )
                        end do

                        do j = 1, no_dofs_per_variable2(1)
                            diffusion_terms = &
                                 0.5_db*dot_product(grad_phi_p(1, qk, :, i), face_normals(:, qk))*phi_m(1, qk, j) &
                                -0.5_db*dot_product(grad_phi_m(1, qk, :, j), face_normals(:, qk))*phi_p(1, qk, i) &
                                -full_dispenal*phi_m(1, qk, j)*phi_p(1, qk, i)

                            convection_terms = &
                                deriv_flux_minus*phi_m(1, qk, j)*phi_p(1, qk, i)

                            face_matrix_mp(1, 1, i, j) = face_matrix_mp(1, 1, i, j) + integral_weighting(qk)*( &
                                diffusion_terms *calculate_transport_diffusion_coefficient(global_points_face(:, qk), &
                                    problem_dim, face_element_region_ids(1)) + &
                                convection_terms*calculate_transport_convection_coefficient(global_points_face(:, qk), &
                                    problem_dim, face_element_region_ids(1)) &
                            )
                        end do
                    end do

                    do i = 1, no_dofs_per_variable2(1)
                        do j = 1, no_dofs_per_variable1(1)
                            diffusion_terms = &
                                -0.5_db*dot_product(grad_phi_m(1, qk, :, i), face_normals(:, qk))*phi_p(1, qk, j) &
                                +0.5_db*dot_product(grad_phi_p(1, qk, :, j), face_normals(:, qk))*phi_m(1, qk, i) &
                                -full_dispenal*phi_p(1, qk, j)*phi_m(1, qk, i)

                            convection_terms = &
                                -deriv_flux_plus*phi_p(1, qk, j)*phi_m(1, qk, i)

                            face_matrix_pm(1, 1, i, j) = face_matrix_pm(1, 1, i, j) + integral_weighting(qk)*( &
                                diffusion_terms *calculate_transport_diffusion_coefficient(global_points_face(:, qk), &
                                    problem_dim, face_element_region_ids(1)) + &
                                convection_terms*calculate_transport_convection_coefficient(global_points_face(:, qk), &
                                    problem_dim, face_element_region_ids(1)) &
                            )
                        end do

                        do j = 1, no_dofs_per_variable2(1)
                            diffusion_terms = &
                                 0.5_db*dot_product(grad_phi_m(1, qk, :, i), face_normals(:, qk))*phi_m(1, qk, j) &
                                +0.5_db*dot_product(grad_phi_m(1, qk, :, j), face_normals(:, qk))*phi_m(1, qk, i) &
                                +full_dispenal*phi_m(1, qk, j)*phi_m(1, qk, i)

                            convection_terms = &
                                -deriv_flux_minus*phi_m(1, qk, j)*phi_m(1, qk, i)

                            face_matrix_mm(1, 1, i, j) = face_matrix_mm(1, 1, i, j) + integral_weighting(qk)*( &
                                diffusion_terms *calculate_transport_diffusion_coefficient(global_points_face(:, qk), &
                                    problem_dim, face_element_region_ids(1)) + &
                                convection_terms*calculate_transport_convection_coefficient(global_points_face(:, qk), &
                                    problem_dim, face_element_region_ids(1)) &
                            )
                        end do
                    end do
                end do
            end if

        end associate

    end subroutine
end module