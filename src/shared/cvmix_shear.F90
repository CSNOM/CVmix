!|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

 module cvmix_shear

!BOP
!\newpage
! !MODULE: cvmix_shear
!
! !DESCRIPTION:
!  This module contains routines to initialize the derived types needed for
!  shear mixing, and to set the viscosity and diffusivity coefficients.
!  Presently this scheme has implemented the shear mixing parameterizations
!  from Pacanowski \& Philander (1981) and Large, McWilliams, \& Doney (1994).
!\\
!\\
!
! !REVISION HISTORY:
!  SVN:$Id$
!  SVN:$URL$

! !USES:

   use cvmix_kinds_and_types, only : cvmix_r8,                &
                                     cvmix_data_type,         &
                                     cvmix_bkgnd_params_type, &
                                     cvmix_shear_params_type
!EOP

   implicit none
   private
   save

!BOP

! !PUBLIC MEMBER FUNCTIONS:

   public :: cvmix_init_shear
   public :: cvmix_coeffs_shear
!EOP

 contains

!BOP

! !IROUTINE: cvmix_init_shear
! !INTERFACE:

  subroutine cvmix_init_shear(CVmix_shear_params, mix_scheme,  &
                              PP_nu_zero, PP_alpha, PP_exp, &
                              KPP_nu_zero, KPP_Ri_zero, KPP_exp)

! !DESCRIPTION:
!  Initialization routine for shear (Richardson number-based) mixing. There are
!  currently two supported schemes - set \verb|mix_scheme = 'PP'| to use the
!  Pacanowski-Philander mixing scheme or set \verb|mix_scheme = 'KPP'| to use
!  the interior mixing scheme laid out in Large et al.
!\\
!\\
!  PP requires setting $\nu_0$ (\verb|PP_nu_zero| in this routine), $alpha$ 
!  (\verb|PP_alpha|), and $n$ (\verb|PP_exp|), and returns
!  \begin{eqnarray*}
!  \nu_{PP} & = & \frac{\nu_0}{(1+\alpha \textrm{Ri})^n} + \nu_b \\
!  \kappa_{PP} & = & \frac{\nu}{1+\alpha \textrm{Ri}} + \kappa_b
!  \end{eqnarray*}
!  Note that $\nu_b$ and $\kappa_b$ are set in \verb|cvmix_init_bkgnd()|, which
!  needs to be called separately from this routine.
! \\
! \\
! KPP requires setting $\nu^0$ (\verb|KPP_nu_zero|, $\textrm{Ri}_0 
! ($\verb|KPP_Ri_zero|), and $p_1$ (\verb|KPP_exp|),  and returns
! $$
! \nu_{KPP} = \left\{
! \begin{array}{r l}
! \nu^0 & \textrm{Ri} < 0\\
! \nu^0 \left[1 - \frac{\textrm{Ri}}{\textrm{Ri}_0}^2\right]^{p_1}
!       & 0 < \textrm{Ri}
!           < \textrm{Ri}_0 \\
! 0     & \textrm{Ri}_0 < \textrm{Ri}
! \end{array} \right.
! $$
!
! !USES:
!  Only those used by entire module.

! !INPUT PARAMETERS:
    character(len=*),         intent(in) :: mix_scheme 
    real(cvmix_r8), optional, intent(in) :: PP_nu_zero, PP_alpha, PP_exp, &
                                            KPP_nu_zero, KPP_Ri_zero, KPP_exp

! !OUTPUT PARAMETERS:
    type(cvmix_shear_params_type), intent(inout) :: CVmix_shear_params
!EOP
!BOC

    select case (trim(mix_scheme))
      case ('PP')
        if (.not.(present(PP_nu_zero) .and. present(PP_alpha) .and.        &
                  present(PP_exp))) then
          print*, "ERROR: you must specify PP_nu_zero, PP_alpha, and PP_exp", &
                  " to use Pacanowski-Philander mixing!"
          stop
        end if
        CVmix_shear_params%mix_scheme = "PP"
        CVmix_shear_params%PP_nu_zero = PP_nu_zero
        CVmix_shear_params%PP_alpha   = PP_alpha
        CVmix_shear_params%PP_exp     = PP_exp

      case ('KPP')
        if (.not.(present(KPP_nu_zero) .and. present(KPP_Ri_zero) .and.       &
                  present(KPP_exp))) then
          print*, "ERROR: you must specify KPP_nu_zero, KPP_alpha, and", &
                  " KPP_exp to use Pacanowski-Philander mixing!"
          stop
        end if
        CVmix_shear_params%mix_scheme  = "KPP"
        CVmix_shear_params%KPP_nu_zero = KPP_nu_zero
        CVmix_shear_params%KPP_Ri_zero = KPP_Ri_zero
        CVmix_shear_params%KPP_exp     = KPP_exp

      case DEFAULT
        print*, "ERROR: ", trim(mix_scheme), " is not a valid choice for ", &
                "shear mixing."
        stop

    end select

!EOC

  end subroutine cvmix_init_shear

!***********************************************************************
!BOP
! !IROUTINE: cvmix_coeffs_shear
! !INTERFACE:

  subroutine cvmix_coeffs_shear(CVmix_vars, CVmix_shear_params,    &
                                CVmix_bkgnd_params, colid, no_diff)

! !DESCRIPTION:
!  Computes vertical tracer and velocity mixing coefficients for
!  shear-type mixing parameterizatiions. Note that Richardson number
!  is needed at both T-points and U-points.
!\\
!\\
!
! !USES:
!  only those used by entire module.

! !INPUT PARAMETERS:
    type(cvmix_shear_params_type),           intent(in) :: CVmix_shear_params
    ! PP mixing requires CVmix_bkgnd_params
    type(cvmix_bkgnd_params_type), optional, intent(in) :: CVmix_bkgnd_params
    ! colid is only needed if CVmix_bkgnd_params%lvary_horizontal is true
    integer,                       optional, intent(in) :: colid
    logical,                       optional, intent(in) :: no_diff

! !INPUT/OUTPUT PARAMETERS:
    type(cvmix_data_type), intent(inout) :: CVmix_vars
!EOP
!BOC

    integer                   :: kw ! vertical cell index
    logical                   :: calc_diff
    real(cvmix_r8), parameter :: one = 1.0_cvmix_r8
    real(cvmix_r8)            :: nu
    real(cvmix_r8)            :: nu_zero, PP_alpha, KPP_Ri_zero, loc_exp
    real(cvmix_r8)            :: bkgnd_diff, bkgnd_visc
    real(cvmix_r8), pointer, dimension(:) :: RICH

    ! Pointer to make the code more legible
    RICH => CVmix_vars%Ri_iface
    if (.not.present(no_diff)) then
      calc_diff = .true.
    else
      calc_diff = .not.no_diff
    end if

    select case (trim(CVmix_shear_params%mix_scheme))
      case ('PP')
        ! Error checks
        if (.not.present(CVmix_bkgnd_params)) then
          print*, "ERROR: can not run PP mixing without background mixing."
          stop
        end if
        if (CVmix_bkgnd_params%lvary_horizontal.and.(.not.present(colid))) then
          print*, "ERROR: background visc and diff vary in horizontal so you", &
                  "must pass column index to cvmix_coeffs_shear"
          stop
        end if

        ! Copy parameters to make the code more legible
        nu_zero  = CVmix_shear_params%PP_nu_zero
        PP_alpha = CVmix_shear_params%PP_alpha
        loc_exp  = CVmix_shear_params%PP_exp

        ! Pacanowski-Philander
        do kw=1,CVmix_vars%nlev+1
          if (CVmix_bkgnd_params%lvary_horizontal) then
            if (CVmix_bkgnd_params%lvary_vertical) then
              bkgnd_diff = CVmix_bkgnd_params%static_diff(colid, kw)
              bkgnd_visc = CVmix_bkgnd_params%static_visc(colid, kw)
            else
              bkgnd_diff = CVmix_bkgnd_params%static_diff(colid, 1)
              bkgnd_visc = CVmix_bkgnd_params%static_visc(colid, 1)
            end if
          else
            if (CVmix_bkgnd_params%lvary_vertical) then
              bkgnd_diff = CVmix_bkgnd_params%static_diff(1, kw)
              bkgnd_visc = CVmix_bkgnd_params%static_visc(1, kw)
            else
              bkgnd_diff = CVmix_bkgnd_params%static_diff(1, 1)
              bkgnd_visc = CVmix_bkgnd_params%static_visc(1, 1)
            end if
          end if
          nu = nu_zero/((one+PP_alpha*RICH(kw))**loc_exp)+bkgnd_visc
          CVmix_vars%visc_iface(kw) = nu
          if (calc_diff) &
            CVmix_vars%diff_iface(kw,1) = nu/(one+PP_alpha*RICH(kw)) + bkgnd_diff
        end do

      case ('KPP')
        ! Copy parameters to make the code more legible
        nu_zero     = CVmix_shear_params%KPP_nu_zero
        KPP_Ri_zero = CVmix_shear_params%KPP_Ri_zero
        loc_exp     = CVmix_shear_params%KPP_exp

        ! Large, et al
        do kw=1,CVmix_vars%nlev+1
            if (RICH(kw).lt.0) then
              CVmix_vars%visc_iface(kw) = nu_zero
            else if (RICH(kw).lt.KPP_Ri_zero) then
              CVmix_vars%visc_iface(kw) = nu_zero * (one -                  &
                   (RICH(kw)/KPP_Ri_zero)**2)**loc_exp
            else ! Ri_g >= Ri_zero
              CVmix_vars%visc_iface(kw) = 0
            end if
        end do

      case DEFAULT
        ! Note: this error should be caught in cvmix_init_shear
        print*, "ERROR: invalid choice for type of shear mixing."
        stop

    end select

!EOC
  end subroutine cvmix_coeffs_shear

end module cvmix_shear