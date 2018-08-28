# SequelQC
PacBio quality check program specifically for Sequel platform




## Installation

### Dependencies
The script has been tested in Linux environment and it requires following programs to be in the path
1. Samtools
2. Python (version 2 or 3)
3. R

Both R and Python should be pre-installed if you're using Linux. Samtools can be easily installed from here:

Once installed, clone the repo, make the scripts executables and add it to your path

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

## Running SequelQC

The `SequelQC.sh` is the main script to execute. It has two required options, `-u` and `-c`. The argument `-u` requires a file listing all the locations of the s`u`bread bam files and `-c` requires a file listing the location of all s`c`raps bam file.

Use the find command to generate these files:

```
find $(pwd) -name "*subreads.bam"  > subreads.txt
find $(pwd) -name "*scraps.bam"  > scraps.txt
```

Once done, execute the `SequelQC.sh` as follows:

```
SequelQC.sh -u subreads.txt -c scraps.txt -n 16
```

## Results
