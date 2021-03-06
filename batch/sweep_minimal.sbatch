#!/bin/bash
#SBATCH --account=rossby
#SBATCH --partition=rossby
#SBATCH --ntasks=16
#SBATCH --cpus-per-task=1
#SBATCH --error=logs/sbatch_minimal.err
#SBATCH --output=logs/sbatch_minimal.out
#SBATCH --job-name=run_exp

# Initial stuff
module purge
module load parallel
module load intel/16.0
module load mkl/11.3
module load netcdf-fortran/4.4.4+intel-16.0
srun="srun --exclusive -N1 -n1 -c1"    # simple
# srun="srun --exclusive -N1 -n16 -c1" # complex
# srun="" # srun not even necessary, perhaps
parallel="parallel --delay .2 -j $SLURM_NTASKS --joblog run_minimal.log"

# Parameter sweeps
# Loop through each of the below parameters, setting the others to their default values
# The runscript will interpret an empty dash '-' as the default parameter
params=""
outfiles=""
u0s="2 5 10 20" # background shear
# famps="1e-10 3e-10 1e-9 3e-9 1e-8 3e-8 1e-7" # forcing amplitude
# tau_fs="0.1 0.2 0.5 1 2 5 10" # friction damping
for u0 in $u0s; do
  params+=" u0=$u0 "
  outfiles+=" u0_$u0 "
done
# for famp in $famps; do
#   params+=" famp=$famp "
#   outfiles+=" famp_$famp "
# done
# for tau_f in $tau_fs; do
#   params+=" tau_f=$tau_f "
#   outfiles+=" tauf_$tau_f "
# done

# Run job, using the parameter series and output files passed above
# For more information on GNU parallel, see:
# https://www.gnu.org/software/parallel/parallel_tutorial.html
$parallel --link "$srun ./run.sh {1} {2} &>logs/{2}.log" ::: $params ::: $outfiles

