# SequelQC validation


Test data set was downloaded from the [PacBio website](https://www.pacb.com/blog/puerto-rican-genome/). Human genome data set, generated for benchmarking purposes by PacBio was used for validation. The steps are descried below:

Data download:

```
wget https://downloads.pacbcloud.com/public/dataset/HG002/Sequel-201810/GRCh38.HG002.bam
wget https://downloads.pacbcloud.com/public/dataset/HG002/Sequel-201810/m54026_180925_081656.subreads.bam
wget https://downloads.pacbcloud.com/public/dataset/HG002/Sequel-201810/m54026_180926_145535.subreads.bam
wget https://downloads.pacbcloud.com/public/dataset/HG002/Sequel-201810/m54043_180926_165101.subreads.bam
wget https://downloads.pacbcloud.com/public/dataset/HG002/Sequel-201804/m54006_180424_190315.subreads.bam
wget https://downloads.pacbcloud.com/public/dataset/HG002/Sequel-201804/m54006_180425_051200.subreads.bam
wget https://downloads.pacbcloud.com/public/dataset/HG002/Sequel-201804/m54006_180428_044608.subreads.bam
wget https://downloads.pacbcloud.com/public/dataset/HG002/Sequel-201804/m54006_180429_213837.subreads.bam
```
SequelQC expects the file names to be in the standard format. Since one of the file was changed, we renamed it have standard name:
```
mv GRCh38.HG002.bam m00000_000000_000000.subreads.bam
```

In order to test different number of SMRTcells with different number of CPU's following fofn (file of file names) was created:

```
ls -1 *.bam |head -n 1 > list_1.fofn
ls -1 *.bam |head -n 2 > list_2.fofn
ls -1 *.bam |head -n 3 > list_3.fofn
ls -1 *.bam |head -n 4 > list_4.fofn
ls -1 *.bam |head -n 5 > list_5.fofn
ls -1 *.bam |head -n 6 > list_6.fofn
ls -1 *.bam |head -n 7 > list_7.fofn
ls -1 *.bam > list_8.fofn
```

Run script for executing the SequelQC script was set-up as follows:

```
#!/bin/bash
module load python
module load r
module load samtools
smrt="$1"
cpu="$2"
mkdir -p run_${smrt}_smrtcells_and_${cpu}_CPUs
echo "using $smrt SMRTcells and $cpu CPUs" &> run_${smrt}_smrtcells_and_${cpu}_CPUs/run_${smrt}_smrtcells_and_${cpu}_CPUs.stderr
(time ./SequelQC.sh -u list_${smrt}.fofn \
    -n $cpu \
    -o run_${smrt}_smrtcells_and_${cpu}_CPUs \
    -v \
    -g a \
    -p a) 2> run_${smrt}_smrtcells_and_${cpu}_CPUs/run_${smrt}_smrtcells_and_${cpu}_CPUs.stderr 1> run_${smrt}_smrtcells_and_${cpu}_CPUs/run_${smrt}_smrtcells_and_${cpu}_CPUs.stdout

````

Commands were generated using a for loop:

```
for cpu in {1..16}; do
   for smrt in {1..8}; do
      echo "./runSeqQC.sh $smrt $cpu";
   done;
done | sort -k3,3 -rn > sequel.cmds
```

The `slurm` script was generated for these commands and were submitted to the HPC cluster:

```
makeSLURMs.py 128 sequel.cmds
for sub in *.sub; do
  sbatch $sub;
done
```

Once all the jobs were complete, the results file was generated as follows:


```
for f in */*stderr; do
   echo -n $(basename ${f%.*}); cat $f |paste - - - -;
done | \
awk '{print $1"\t"$3"\t"$5"\t"$7}' |\
sed -e 's/_smrtcells_and_/\t/' -e 's/run_//g' -e 's/_CPUs//g' -e 's/s//g' -e 's/m/:/g' > benchmark_results.txt
```
