
"""
    Tcmb(z::Real)

Computes the temperature of the CMB at redshift `z`.
"""
Tcmb(z::Real) = ( 2.728 * ( 1.0 + z ) )


"""
    kSzPrefac(ν::Real, z::Real, DI_over_I::Bool)

Prefactor for the kinetic Sunyaev-Zel'dovich effect.
"""
function kSzPrefac(ν::Real, z::Real, DI_over_I::Bool)

    c   = 2.9979e10
    σ_T = 6.65245e-25
    
    kSzPrefac  = -1.0 * σ_T / c

    if DI_over_I
        h   = 6.6261e-27
        k_B = 1.38066e-16
        x   = h * ν / ( k_B * Tcmb(z) )

        kSzPrefac *= exp(x) - 1 / (x * exp(x))
    end

    return kSzPrefac
end


"""
    yPrefac()

Prefactor for the Compton-Y parameter.
"""
function yPrefac()   

    k_B = 1.38066e-16
    c   = 2.9979e10
    σ_T = 6.65245e-25
    m_e = 9.10953e-28

    return σ_T * k_B / (m_e * c * c)
end

"""
    kinetic_SZ(n_cm3::Real, vel_y_cgs::Real, 
                    ν::Real=1.e9, z::Real=0.0; 
                    DI_over_I::Bool=false)

Computes the kinetic Sunyaev-Zel'dovich effect from electron density `n_cm3` and velocity in y-direction to the projection plane in cgs units `vel_y_cgs`.
If `DI_over_I` is set to `true` you also need to provide an observation frequency `ν` and redshift `z`.
"""
function kinetic_SZ(n_cm3::Real, vel_y_cgs::Real, 
                    ν::Real=1.e9, z::Real=0.0; 
                    DI_over_I::Bool=false)
    return kSzPrefac(ν, z, DI_over_I) * n_cm3 * vel_y_cgs
end

"""
    comptonY(n_cm3::Real, T_K::Real, z::Real)

Computes the Compton-Y parameter from electron density `n_cm3` and temperature `T` in Kelvin at redshift `z`.
"""
function comptonY(n_cm3::Real, T_K::Real, z::Real)
    return yPrefac() * n_cm3 * ( T_K - Tcmb(z) )
end

"""
    tSzPrefac(ν::Real, z::Real)

Computes the prefactor for the thermal Sunyaev-Zel'dovich effect.
"""
function tSzPrefac(ν::Real, z::Real, DI_over_I::Bool)
    h   = 6.6261e-27
    k_B = 1.38066e-16
    x   = h * ν / ( k_B * Tcmb(z) )
    tSzPrefac = (x * (exp(x) + 1.0) / (exp(x) - 1.0) - 4.0)

    if DI_over_I
        tSzPrefac *= exp(x) - 1 / (x * exp(x))
    end

    return tSzPrefac

end

"""
    thermal_SZ(n_cm3::Real, T::Real, z::Real=0.0, ν::Real=1.44e9)

Computes the thermal Sunyaev-Zel'dovich effect for electron density `n_cm3` and temperature `T` in Kelvin at redshift `z` and observer frequency `ν`.
"""
function thermal_SZ(n_cm3::Real, T::Real, 
                    z::Real=0.0, ν::Real=1.44e9; 
                    DI_over_I::Bool=false)
    return tSzPrefac(ν, z, DI_over_I) * comptonY(n_cm3, T, z)
end