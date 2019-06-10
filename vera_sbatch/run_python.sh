#!/bin/bash
#SBATCH -J python  		# Name of job
#SBATCH -o python.out	# Output log
#SBATCH -N 1            # Number of nodes
#SBATCH -n 1            # Number of processes
#SBATCH -t 2-00         # Walltime limit (days-hours)
#SBATCH -A C3SE2019-1-4 # Project
#SBATCH -p vera         # Partition

# Get input options
script=$1

# Load python3
module load iccifort/2018.3.222-GCC-7.3.0-2.30  impi/2018.3.222 Python/3.6.7

# Run analysis
echo $script
python $script
echo $?