# How ParticLas works

## Physical model
In ParticLas, the (single species) BGK-Boltzmann equation
```math
    \frac{\partial f}{\partial t} + v\cdot\frac{\partial f}{\partial x} = \frac{1}{\tau}(f_t - f)
```
is solved. Here, $f=f(x,v,t)$ is the density function at position $x$, velocity $v$ and time $t$. The right hand side is the so-called *BGK* collision operator, where $\tau$ is the *relaxation time* and $f_t$ is the target distribution function.
In the original BGK model, the target distribution function is a simple Maxwellian distribution defined by the number density $n$, the macroscopic velocity $u$ and the temperature $T$.

## Numerical model
The density function is approximated by a large number of simulation particles
```math
    f(x,v,t)\approx\sum_p{\omega_p\delta(x-x_p)\delta(v-v_p)}.
```
Each particle is defined by its position $x_p$ and velocity $v_p$. The *weighting factor* $\omega_p$ defines, how many "physical" particles are represented by a single simulation particle. Since there is a huge number of particles in reality, this weighting factor is set to a fairly large number ($\omega_p=5\cdot 10^{15}$ in ParticLas).

### Time stepping
When using particles to solve the Boltzmann equation, one usually splits the equation into a movement operator
```math
    \frac{\partial f}{\partial t} + v\cdot\frac{\partial f}{\partial x} = 0
```
and a collision operator
```math
    \frac{\partial f}{\partial t} = \frac{1}{\tau}(f_t - f)
```
that are solved successively.
This procedure is often called *Operator splitting*.

## Movement Step
### Particle insertion
Before the particles are moved, new particles are inserted at the left free-stream boundary.
The particles are inserted assuming a Maxwellian distribution (thermal equilibrium) with a given temperature and inflow velocity.
The density defines the actual number of particles inserted in each time step.

The two sliders in ParticLas directly set the velocity and density of the inflow distribution.
The velocity can be set between $5000\,\mathrm{m}/\mathrm{s}$ and $10000\,\mathrm{m}/\mathrm{s}$.
The density is calculated from the altitude $h$
```math
    \rho = 1.225\,\frac{\mathrm{kg}}{\mathrm{m}^3} \cdot \exp\left(-0.11856\,\frac{1}{\mathrm{m}} \cdot h\right)
```
where the altitude can be set between $90\,\mathrm{km}$ and $120\,\mathrm{km}$.

### Particle movement
In the movement step, the particle positions are updated by a simple push:
```math
    x_p^{new} = x_p + \Delta t v_p
```
However, during that push, the particle may cross either a wall or a free-stream boundary (out-/inflow).
If it hits a wall, it is reflected according to the specific boundary conditions and pushed for the remaining time step.
If it crosses a free-stream boundary, it is deleted.

### Wall boundary condition
When Particles hit a wall, two types of reflection can occur.
First, there is the *specular reflection*, where the particle is reflected just like a mirror.
The other type of reflection is a *diffuse reflection*.
Here, the particle is reflected with the velocity sampled from a Maxwellian inflow with the wall velocity and temperature.

In ParticLas, a slider that sets the *accomodation coefficient* can be used to combine these two types of reflections.
This coefficient simply defines the probability of a diffuse reflection vs a specular reflection.
If the accomodation coefficient is 0.3, then a particle hitting the wall has a 30% chance of a specular reflection and a 70% chance of a diffuse reflection.
The temperature of the walls is set to $T_w=600\,\mathrm{K}$.

## Collision Step
In order to calculate the relaxation time and target distribution function, the macroscopic variables (number density, bulk velocity and temperature) have to be calculated.
For this, the rectangular domain is divided into $120\times 80$ cells.
In each cell, constant macroscopic values are estimated from the particle velocities.

After $\tau$ and $f_t$ are calculated, a relaxation probability for each particle is calculated.
If the particle relaxes, its velocity is sampled from $f_t$.

Analytically, the momentum and energy in each cell are conserved during the collision step.
However, due to the limited number of particles, an additional step that forces conservation of both values is included.

## Simulation Parameters
|  |  |
| --- | --- |
| Species | Argon |
| Domain length | $16/9\,\mathrm{m}\times 1\,\mathrm{m}$
| Time step | $10^{-6}\,\mathrm{s}$

## Limitations & Simplifications
1. Zu großer Zeitschritt
2. Große Zellen / Wenige Partikel
3. 2D Rechnung (NICHT achsensymmetrisch)
4. Einfacher Kollisionsoperator
5. Wände beeinflussen Berechnung der Makroskopischen größen nicht
6. Einfaches Wandinteraktionsmodell
7. Nur eine (neutrale) Spezies, keine Reaktionen