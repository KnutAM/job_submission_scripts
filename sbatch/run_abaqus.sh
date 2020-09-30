#!/bin/bash
#SBATCH -N 1            # Number of nodes
#SBATCH -n 10           # Number of processes

## Example calling line:
 # sbatch -J myjob -o mylog.out -n 10 ~/../job_submission_scripts/sbatch/run_abaqus.sh -i my.inp -u umat.o -s "12h"
 # Input between "sbatch" and "~/../job_submission_scripts/sbatch/run_abaqus.sh" set sbatch options (overrides what is in this file)
 # Inputs after run_abaqus.sh sets input options to this file, as follows:
 
 # Inputs
 # i    which input file to run, either absolute path or relative path from your current location. (Your current location will be your submission directory)
 # u    which umat to use (in the umat path as specified below)
 # o    If you need to use the oldjob=* option in abaqus command, specify * here
 # s    The backup interval, when to copy all files back to submit directory in case simulation crashes before it is completed (or time-limit is hit)

# Define default paths
umat_path=$SNIC_BACKUP/abaqus_umats    # Path where your compiled umats are located
 
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
rm 'slurm-'$SLURM_JOB_ID'.out'	# Remove log-file to prevent it from being copied back and overwritten.

# Setup backup
while sleep $copytime; do
  rsync * $SLURM_SUBMIT_DIR/
done &

LOOPPID=$!

# Check if umat is given
if [ -z $umat ]; then
    # No umat chosen (assume it is not required
    if [ -z $oldjob ]; then
        abaqus job=$inputfile cpus=$SLURM_NPROCS interactive
    else
        abaqus job=$inputfile oldjob=$oldjob cpus=$SLURM_NPROCS interactive
    fi
else
    cp -p $umat_path/$umat $TMPDIR
    module load intel
    if [ -z $oldjob ]; then
        abaqus job=$inputfile user=$umat cpus=$SLURM_NPROCS interactive
    else
        abaqus job=$inputfile oldjob=$oldjob user=$umat cpus=$SLURM_NPROCS interactive
    fi
fi
kill $LOOPPID

# Copy back output data and change directory, option p ensures attributes preserved, r recursively (include folder and their files)
cp -pr $TMPDIR/* $SLURM_SUBMIT_DIR # Copy all data
