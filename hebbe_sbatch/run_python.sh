#!/bin/bash
#SBATCH -J python       # Name of job
#SBATCH -o p.out		# Output log
#SBATCH -N 1            # Number of nodes
#SBATCH -n 1            # Number of processes
#SBATCH -t 2-00         # Walltime limit (days-hours)
#SBATCH -A C3SE507-15-6 # Project (main queue: "C3SE2018-1-17", mob: "C3SE507-15-6")
#SBATCH -p mob          # Partition ("hebbe" main queue, "mob" private at MoB)

# Get input options
script=$1

# Load python3
module load ifort/2018.3.222-GCC-7.3.0-2.30  impi/2018.3.222 Python/3.7.0

# Run analysis
echo $script
python $script
echo $?