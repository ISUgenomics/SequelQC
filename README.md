# SequelQC
SequelQC is a quality check program specifically for the PacBio Sequel platform that quickly processes raw sequence data from multiple SMRTcells producing multiple statistics and publication quality plots describing the quality of the data including N50, read length and count statistics, PSR, and ZOR.

## Installation

### Dependencies
The script has been tested in Linux environment and it requires following programs to be in the path
1. Samtools
2. Python (version 2 or 3)
3. R

Both R and Python should be pre-installed if you're using Linux. Samtools can be easily installed from here:
http://www.htslib.org

### SequelQC installation
Once installed, clone the github repository, make the scripts executables and add it to your path like so:

```
git clone https://github.com/ISUgenomics/SequelQC.git
cd SequelQC
chmod +x *.sh *.py
export PATH=$PATH:"$(pwd)"
```
For a more permanent solution, you can add the export path line to your `.bashrc` file

```
PATH=$PATH:/path/to/SequelQC
```

No compilation is required so you are now done with installation! 

## Running SequelQC

The `SequelQC.sh` is the main script to execute. This script will call all other necessary scripts. You can test whether the main script was properly installed by calling the script alone:

```
./SequelQC.sh
```

or 

```
bash SequelQC.sh
```

This should bring up the help menu.

`SequelQC` has two required arguments, `-u` and `-c`. The argument `-u` requires a file listing all the locations of the s`u`bread bam files and `-c` requires a file listing the location of all s`c`raps bam file.  In each case the format is simply one filename per line.  Note that `SequelQC` requires scraps files to run so don't throw them away!

The easy way to generate these files is using the find command:

```
find $(pwd) -name "*subreads.bam"  > subreads.txt
find $(pwd) -name "*scraps.bam"  > scraps.txt
```

Once done, to run `SequelQC` using all default arguments execute `SequelQC.sh` as follows:

```
./SequelQC.sh -u subreads.txt -c scraps.txt
```

or 

```
bash SequelQC.sh -u subreads.txt -c scraps.txt
```

## Other Arguments

`SequelQC` has many other arguments that are worth considering before running it on your data. You can get an updated and comprehensive summary of these arguments by accessing the help menu.  The help menu will present itself if the user calls `SequelQC` with no arguments, calls `SequelQC` with the -h argument, or makes any number of mistakes while running the program.

One important argument is `-n`, which sets the number of threads to use for samtools.  The default is 1, but the more threads used the faster the program will run.  

Another optional argument is `-o`, which sets the directory for outputting all final tables and plots.  The default is to make a folder called SequelQCresults and put the final table and plots there.  If the folder SequelQCresults is already present when you run `SequelQC`, all contents within the folder will be erased before the new results are written there.  For that reason if you plan to run the program on multiple datasets you'll either want to do it in seperate folders or use the -o option to create multiple output folders.

The '-v' argument allows the user to get updates on what `SequelQC` is doing as it does it, and the '-k' argument tells `SequelQC` to keep all intermediate files.  These files are created in the directory `SequelQC` is ran in and are normally deleted before the program finishes.  The '-k' parameter is very useful for rerunning `SequelQC` using different plotting parameters or using a custom R script.  It could also be used to give the user raw data they would not otherwise be given. Along with the '-k' parameter, if the user has already generated intermediate files, the user can comment out the lines in `SequelQC.sh` that call samtools and Python.  This will cut out the large majority of the runtime.  As for using a custom R script for plotting the user can make their own plotting script or modify ours and then simply replace the name of our R scirpt in `SequelQC.sh` with the name of the user's script.

The '-g' argument allows the user to see fewer groups of reads in the final table and plots.  By default...


