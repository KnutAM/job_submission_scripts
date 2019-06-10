#!/bin/bash
#SBATCH -J abaqus       # Name of job
#SBATCH -o aba.out      # Output log default name
#SBATCH -N 1            # Number of nodes
#SBATCH -n 10           # Number of processes
#SBATCH -t 7-00         # Walltime limit (days-hours)
#SBATCH -A C3SE507-15-6 # Project (main queue: "C3SE2018-1-17", mob: "C3SE507-15-6")
#SBATCH -p mob          # Partition ("hebbe" main queue, "mob" private at MoB)

## Example calling line:
 # sbatch -J myjob -o mylog.out -n 10 ~/jobscripts/run_abaqus.sh -i my.inp -u umat.o -s "12h"

# Define default paths
umat_path=$HOME/abaqus_umats
 
# Get input options
while getopts ":i:u:o:s:" opt; do
  case $opt in
    i)
      inputfile=$OPTARG
      ;;
    u)
      umat=$OPTARG
      ;;
    o)
      oldjob=$OPTARG
      ;;
    s)
      copytime=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Check that input file is given
if [ -z $inputfile ]; then
    echo "No input file selected, this is mandatory!"
    exit 1
fi

if [ -z $copytime ]; then
    copytime="10d"
fi

# Setup environment
cp -pr * $TMPDIR
module load ABAQUS
cd $TMPDIR

# Setup backup
while sleep $copytime; do
  rsync * $SLURM_SUBMIT_DIR/
done &
LOOPPID=$!

# Check if umat is given
if [ -z $umat ]; then
    # No umat chosen (assume it is not required
    if [ -z $oldjob ]; then
        abaqus job=$inputfile cpus=$SLURM_NPROCS
    else
        abaqus job=$inputfile oldjob=$oldjob cpus=$SLURM_NPROCS
    fi
else
    cp -p $umat_path/$umat $TMPDIR
    module load intel
    if [ -z $oldjob ]; then
        abaqus job=$inputfile user=$umat cpus=$SLURM_NPROCS
    else
        abaqus job=$inputfile oldjob=$oldjob user=$umat cpus=$SLURM_NPROCS
    fi
fi

kill $LOOPPID

# Copy back output data and change directory, option p ensures attributes preserved, r recursively (include folder and their files)
cp -pr $TMPDIR/* $SLURM_SUBMIT_DIR # Copy all data