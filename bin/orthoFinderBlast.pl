#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($query,$database,$filePath,$queryNumber,$dataNumber,$previousBlasts,$sequences_id_file,$species_id_file);

&GetOptions("query=s"=> \$query,
            "database=s"=> \$database,
	    "sequenceIDs=s"=> \$sequences_id_file,
	    "speciesIDs=s"=> \$species_id_file
           );

# Read species ID file
open my $fh_species, '<', $species_id_file or die "Cannot open $species_id_file: $!";
my %species_map;
while (my $line = <$fh_species>) {
    chomp $line;
    if ($line =~ /^(\d+):\s+(\S+)\.fasta\.fasta/) {
        my ($id, $species) = ($1, $2);
        $species_map{$id} = $species;
    }
}
close $fh_species;

# Read sequences ID file
open my $fh_sequences, '<', $sequences_id_file or die "Cannot open $sequences_id_file: $!";
my %sequences_map;
while (my $line = <$fh_sequences>) {
    chomp $line;
    if ($line =~ /^(\d+_\d+):\s+(.+)/) {
        my ($new, $original) = ($1, $2);
        $sequences_map{$new} = $original;
    }
}
close $fh_sequences;


if ($query =~ /^(.+)Species(\d+).fa/) {
    $filePath = $1;
    $queryNumber = $2;
}
else {
    die;
}
if ($database =~ /^(.+)Species(\d+).fa/) {
    $dataNumber = $2;
}
else {
    die;
}

my $queryOrganism = $species_map{$queryNumber};
my $dataOrganism = $species_map{$dataNumber};

if (-e "/previousBlasts/${queryOrganism}_${dataOrganism}.txt.gz") {
    system("cp /previousBlasts/${queryOrganism}_${dataOrganism}.txt.gz ./Blast${queryNumber}_${dataNumber}.txt.gz");
}
else {
    system("diamond blastp --ignore-warnings -d ${filePath}diamondDBSpecies${dataNumber}.dmnd -q ${filePath}Species${queryNumber}.fa -o Blast${queryNumber}_${dataNumber}.txt.gz -f 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen nident positive qframe qstrand gaps qseq --more-sensitive -p 1 --quiet -e 0.001 --compress 1");
}
