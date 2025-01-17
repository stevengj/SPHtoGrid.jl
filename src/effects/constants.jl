global const k_B        = 1.38066e-16
global const c_light    = 2.9979e10
global const σ_T        = 6.65245e-25
global const m_e        = 9.10953e-28
global const m_p        = 1.6726e-24
global const h_planck   = 6.6261e-27
global const q_e        = 1.602176487e-20 * c_light
global const yPrefac    = σ_T * k_B / (m_e * c_light^2)
global const eV2cgs     = 1.60218e-12
global const cgs2eV     = 1.0/eV2cgs
global const C_crit     = 3q_e / ( 4π * m_e * c_light ) # Donnert+16, MNRAS 462, 2014–2032 (2016), Eg. 20 
                                                        #  -> converted to dimensionless momentum
global const γ          = 5.0/3.0
global const mJy_factor = 1.e26       # conversion factor from [erg/cm^3/Hz/s] to mJy/cm.